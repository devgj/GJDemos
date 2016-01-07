//
//  ScanViewController.swift
//  imooc
//
//  Created by GJ on 15/12/18.
//  Copyright © 2015年 imooc. All rights reserved.
//

import UIKit
import AVFoundation

private let animationKey = "translationkey"

class ScanViewController: UIViewController {
  
  @IBOutlet private weak var scanFrameView: UIImageView!
  @IBOutlet private weak var scanView: UIView!
  @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
  @IBOutlet private weak var loadingView: UIView!
  @IBOutlet private weak var lampButton: UIButton!
  @IBOutlet private weak var lampButtonRightMarginConstraint: NSLayoutConstraint!
  @IBOutlet private weak var imagePickerButtonWidthConstraint: NSLayoutConstraint!
  
  private weak var animationImageView: UIImageView!
  private var session: AVCaptureSession?
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var deviceInput: AVCaptureDeviceInput?
  private var isCaptureValidResult = false
}

// MARK: - Life Cycle
extension ScanViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    configViews()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    isCaptureValidResult = false
    
    // start loading
    startLoading()
    delay(0.2) { self.getAuthorization() }
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    lampTurnOff()
    lampButton.selected = false
  }
}

// MARK: - Setup View
extension ScanViewController {
  private func configViews() {
    view.backgroundColor = UIColor.blackColor()
    // 冲击波
    self.setupAnimationImageView()
  }
  private func setupAnimationImageView() {
    // 添加动画imageView
    let animationImageView = UIImageView()
    animationImageView.image = UIImage(named: "scan_net")
    var frame = self.scanFrameView.bounds
    frame.origin.y = -frame.size.height
    animationImageView.frame = frame
    self.scanFrameView.addSubview(animationImageView)
    self.animationImageView = animationImageView
  }
}

// MARK: - Event Response
extension ScanViewController {
  @IBAction func onClickLampButton(sender: UIButton) {
    sender.selected = !sender.selected
    
    if sender.selected {
      // 开灯
      lampTurnOn()
    } else {
      // 关灯
      lampTurnOff()
    }
  }

  @IBAction func onClickImagePickerButton() {
    // 打开相册
    openPhotosAlbum()
  }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
// 该方法调用频率很高
extension ScanViewController: AVCaptureMetadataOutputObjectsDelegate {
  func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
    let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject
    if let metadataObject = metadataObject {
      if metadataObject.type == AVMetadataObjectTypeQRCode &&
          !self.isCaptureValidResult {
        self.isCaptureValidResult = true
        if let stringValue = metadataObject.stringValue {
          showMessage(stringValue)
        }
      }
    }
  }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension ScanViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
    picker.dismissViewControllerAnimated(true, completion: nil)
    // 先取编辑之后的图片，取不到再取原图
    var image = editingInfo?[UIImagePickerControllerEditedImage] as? UIImage
    if image == nil {
      image = editingInfo?[UIImagePickerControllerOriginalImage] as? UIImage
    }
   
    if image == nil {
      return
    }
    
    // 解析图片中的二维码
    let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
    if let ciimage = CIImage(image: image!) {
      let features = detector.featuresInImage(ciimage)
      for feature in features {
        if let feature = feature as? CIQRCodeFeature {
          showMessage(feature.messageString)
          break
        }
      }
    }
  }
}

// MARK: - Private Method
extension ScanViewController {
  
  private func startLoading() {
    self.loadingView.hidden = false
    self.scanView.hidden = true
    self.animationImageView.layer.removeAnimationForKey(animationKey)
    self.activityIndicatorView.startAnimating()
  }
  
  private func stopLoading() {
    self.activityIndicatorView.stopAnimating()
    self.loadingView.hidden = true
    self.scanView.hidden = false
    
    // 开始动画
    let animation = CABasicAnimation(keyPath: "transform.translation.y")
    animation.duration = 1.5
    animation.repeatCount = MAXFLOAT
    animation.fromValue = 0
    animation.toValue = self.animationImageView.frame.size.height
    self.animationImageView.layer.addAnimation(animation, forKey:animationKey)
  }
  
  // 获取访问相机授权
  private func getAuthorization() {
    let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
    switch(authorizationStatus) {
    case .NotDetermined:
      AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (success: Bool) -> Void in
        if success {
          self.setupCapture()
        }
      })
      break
    case .Authorized:
      self.setupCapture()
      break
    case .Restricted, .Denied:
      UIAlertView(title: "请在iPhone的“设置-隐私-相机”选项中，允许慕课网访问你的相机", message: nil, delegate: nil, cancelButtonTitle: "好").show()
      self.stopLoading()
      break
    }
  }
  
  // 核心部分: 准备输入输出
  private func setupCapture() {
    // 该方法在viewDidAppear里面调用，
    // 这里防止重复创建session
    if self.session != nil {
      self.session!.startRunning()
      self.previewLayer?.hidden = false
      self.stopLoading()
      return
    }
    let session = AVCaptureSession()
    self.session = session
    let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    do {
      let deviceInput = try AVCaptureDeviceInput(device: device)
      self.deviceInput = deviceInput
      if session.canAddInput(deviceInput) {
        session.addInput(deviceInput)
      }
      let metadataOutput = AVCaptureMetadataOutput()
      metadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
      if session.canAddOutput(metadataOutput) {
        session.addOutput(metadataOutput)
      }
      metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
      let previewLayer = AVCaptureVideoPreviewLayer(session: session)
      previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
      previewLayer.frame = self.view.frame
      self.view.layer.insertSublayer(previewLayer, atIndex: 0)
      self.previewLayer = previewLayer
      
      session.startRunning()
      self.stopLoading()
    } catch let error {
      print(error)
    }
  }
  
  // 打开相册
  private func openPhotosAlbum() {
    let picker = UIImagePickerController()
    picker.sourceType = .PhotoLibrary
    picker.delegate = self
    picker.allowsEditing = true
    self.presentViewController(picker, animated: true, completion: nil)
  }
  
  private func delay(time: Double, block: dispatch_block_t) {
    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC)))
    dispatch_after(delayTime, dispatch_get_main_queue(), block)
  }
  
  private func lampTurnOn() {
    self.lampTurnOn(true)
  }
  
  private func lampTurnOff() {
    self.lampTurnOn(false)
  }
  
  // 开灯/关灯
  private func lampTurnOn(on: Bool) {
    let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    guard device.hasFlash && device.hasTorch else {
      return
    }
    if let deviceInput = self.deviceInput {
      let torch = deviceInput.device.torchMode
      
      // 开灯操作，已经处于开灯状态
      if on && torch == .On {
        return
      }
      
      // 关灯操作，已经处于关灯状态
      if !on && torch == .Off {
        return
      }
      
      do {
        try deviceInput.device.lockForConfiguration()
        deviceInput.device.torchMode = on ? .On : .Off
        deviceInput.device.unlockForConfiguration()
      } catch let error {
        print("\(error)")
      }
    }
  }
  
  private func showMessage(message: String) {
    let alertController = UIAlertController(title: "结果", message: message, preferredStyle: .Alert)
    let action = UIAlertAction(title: "确定", style: .Default, handler: { action in
      self.isCaptureValidResult = false
    })
    alertController.addAction(action)
    presentViewController(alertController, animated: true, completion: nil)
  }
}


