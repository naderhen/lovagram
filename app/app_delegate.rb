class AppDelegate
  attr_reader :window

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)

    main_controller = MainController.alloc.initWithNibName(nil, bundle: nil)
    @window.rootViewController = UINavigationController.alloc.initWithRootViewController(main_controller)

    @window.makeKeyAndVisible


    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, true)
    documentsDir = paths.objectAtIndex(0)
    
    fileName = "video.mp4"
    fullPath = documentsDir.stringByAppendingPathComponent(fileName)

    size = CGSizeMake(800, 600)

    InstagramClient.sharedClient.authenticate
    true
  end

  def application(application, openURL:url, sourceApplication:sourceApplication, annotation:annotation)
    if url.absoluteString
      InstagramClient.sharedClient.handleOAuthCallBack(url.absoluteString)
      controller = FeedController.new
      @window.rootViewController.pushViewController(controller, animated:true)
    end
    true
  end

end
