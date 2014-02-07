class VideoPreviewController < UIViewController

  def viewDidLoad
    super
    rmq.stylesheet = VideoPreviewControllerStylesheet
    rmq(self.view).apply_style :root_view

    @video_view = rmq.append(UIView, :video_view).get

    path = NSHomeDirectory().stringByAppendingPathComponent("Documents/test_output.mp4")
    fileUrl = NSURL.fileURLWithPath(path)

    @avPlayer = AVPlayer.playerWithURL(fileUrl)

    layer = AVPlayerLayer.playerLayerWithPlayer(@avPlayer)
    @avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone
    layer.frame  = UIScreen.mainScreen.bounds
    self.view.layer.addSublayer(layer)
    @avPlayer.play
  end

  # Remove if you are only supporting portrait
  def supportedInterfaceOrientations
    UIInterfaceOrientationMaskAll
  end

  # Remove if you are only supporting portrait
  def willAnimateRotationToInterfaceOrientation(orientation, duration: duration)
    rmq.all.reapply_styles
  end
end
