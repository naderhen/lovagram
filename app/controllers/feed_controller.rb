class FeedController < UICollectionViewController
  # In app_delegate.rb or wherever you use this controller, just call .new like so:
  #   @window.rootViewController = FeedController.new
  #
  # Or if you're adding using it in a navigation controller, do this
  #  main_controller = FeedController.new
  #  @window.rootViewController = UINavigationController.alloc.initWithRootViewController(main_controller)

  FEED_CELL_ID = "FeedCell"
  
  def self.new(args = {})
    # Set layout 
    layout = UICollectionViewFlowLayout.alloc.init
    self.alloc.initWithCollectionViewLayout(layout)
  end

  def viewDidLoad
    super

    self.title = "Feed"

    @client = InstagramClient.sharedClient
    @client.delegate = self

    @client.fetchFeed("feed")

    @entries = []
    @selected = []

    @rect = CGSizeMake(640, 640)

    rmq.stylesheet = FeedControllerStylesheet

    collectionView.tap do |cv|
      cv.registerClass(FeedCell, forCellWithReuseIdentifier: FEED_CELL_ID)
      cv.delegate = self
      cv.dataSource = self
      cv.allowsSelection = true
      cv.allowsMultipleSelection = false
      rmq(cv).apply_style :collection_view
    end

    self.navigationItem.tap do |nav|
      nav.rightBarButtonItem = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemAction,
                                                                           target: self, action: :createVideo)
    end
  end

  # Remove if you are only supporting portrait
  def supportedInterfaceOrientations
    UIInterfaceOrientationMaskAll
  end

  # Remove if you are only supporting portrait
  def willAnimateRotationToInterfaceOrientation(orientation, duration: duration)
    rmq(:reapply_style).reapply_styles
  end

  # Instagram Client Delegate

  def handle_success(response, tag)
    if tag == "feed"
      @entries = response.object["data"]
      collectionView.reloadData
    end
  end

  def numberOfSectionsInCollectionView(view)
    1
  end
 
  def collectionView(view, numberOfItemsInSection: section)
    @entries.size 
  end
    
  def collectionView(view, cellForItemAtIndexPath: index_path)
    view.dequeueReusableCellWithReuseIdentifier(FEED_CELL_ID, forIndexPath: index_path).tap do |cell|
      rmq.build(cell) unless cell.reused

      cell.update(@entries[index_path.row])
    end
  end

  def collectionView(view, didSelectItemAtIndexPath: index_path)
    cell = view.cellForItemAtIndexPath(index_path)
    entry = @entries[index_path.row]
    url = entry["images"]["standard_resolution"]["url"]

    if cell.chosen
      cell.setChosen(false)
      @selected.delete_if {|en| en["url"] == url}
    else
      cell.setChosen(true)
      data = NSData.dataWithContentsOfURL(NSURL.URLWithString(url))
      @selected << {"url" => url, "image" => UIImage.imageWithData(data)}
    end
    ap @selected.count
  end

  def createVideo
    error = nil
    fileMgr = NSFileManager.defaultManager
    documentsDirectory = NSHomeDirectory().stringByAppendingPathComponent("Documents")
    videoOutputPath = documentsDirectory.stringByAppendingPathComponent("test_output.mp4")

    if !fileMgr.removeItemAtPath(videoOutputPath, error: Pointer.new(:object, error))
      ap "Unable to delete file"
    end

    self.writeImageAsMovie(@selected, toPath:videoOutputPath, size:@rect, duration:10)
  end

  def writeImageAsMovie(array, toPath:path, size:size, duration:duration)
    error = nil
    fps = 30
    videoWriter = AVAssetWriter.alloc.initWithURL(NSURL.fileURLWithPath(path), fileType:AVFileTypeMPEG4, error:error)

    videoSettings = {AVVideoCodecKey => AVVideoCodecH264, AVVideoWidthKey => size.width, AVVideoHeightKey => size.height}
    writerInput = AVAssetWriterInput.assetWriterInputWithMediaType(AVMediaTypeVideo, outputSettings:videoSettings).retain

    adaptor = AVAssetWriterInputPixelBufferAdaptor.assetWriterInputPixelBufferAdaptorWithAssetWriterInput(writerInput, sourcePixelBufferAttributes:nil)
    
    videoWriter.addInput(writerInput)
    videoWriter.startWriting
    videoWriter.startSessionAtSourceTime(KCMTimeZero)
    buffer = nil

    frameCount = 0
    numberOfSecondsPerFrame = 2
    frameDuration = fps * numberOfSecondsPerFrame

    ap "starting write"
    ap "=========="
    array.each do |entry|
      img = entry["image"]
      buffer = pixelBufferFromCGImage(img.CGImage, size:@rect)

      append_ok = false
      j = 0

      while (!append_ok && j < 30) do
        if writerInput.isReadyForMoreMediaData
          ap "processing for framecount #{frameCount}"
          frameTime = CMTimeMake(frameCount * frameDuration, fps)
          append_ok = adaptor.appendPixelBuffer(buffer, withPresentationTime:frameTime)

          if !append_ok
            error = videoWriter.error
            if !error.nil?
              ap "error: #{error}, #{error.userInfo}"
            end
          end
        else
          ap "adaptor not ready"
          NSThread.sleepForTimeInterval(0.1)
        end
        j += 1
      end

      if (!append_ok)
        ap "error"
      end
      frameCount += 1
    end
    ap "=========="

    writerInput.markAsFinished
    videoWriter.finishWriting
    CVPixelBufferPoolRelease(adaptor.pixelBufferPool)
    ap "DONE"
  end

  def pixelBufferFromCGImage(image, size:imageSize)
    options = {KCVPixelBufferCGImageCompatibilityKey => 1, KCVPixelBufferCGBitmapContextCompatibilityKey => 1}

    pxbuffer = Pointer.new(:object)
    status = CVPixelBufferCreate(KCFAllocatorDefault, imageSize.width, imageSize.height, KCVPixelFormatType_32ARGB, options, pxbuffer)
    
    CVPixelBufferLockBaseAddress(pxbuffer[0], 0)
    pxdata = CVPixelBufferGetBaseAddress(pxbuffer[0])
    
    rgbColorSpace = CGColorSpaceCreateDeviceRGB()

    context = CGBitmapContextCreate(pxdata, imageSize.width, imageSize.height, 8, 4 * imageSize.width, rgbColorSpace, KCGImageAlphaNoneSkipFirst)

    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image)

    CGColorSpaceRelease(rgbColorSpace)
    # TODO THIS
    # CGContextRelease(context)
    
    CVPixelBufferUnlockBaseAddress(pxbuffer[0], 0)
    return pxbuffer[0]
  end

end



    # buffer = pixelBufferFromCGImage(array.objectAtIndex(0).CGImage, size:@rect)
    # buffer_pointer = Pointer.new(:object, buffer)

    # CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool, buffer_pointer)
    # adaptor.appendPixelBuffer(buffer, withPresentationTime:KCMTimeZero)

    # array.each_with_index do |image, idx|
    #   if writerInput.isReadyForMoreMediaData
    #     frameTime = CMTimeMake(1 * 10, 10)
    #     lastTime = CMTimeMake(idx * 10, 10)
    #     presentTime = CMTimeAdd(lastTime, frameTime)

    #     buffer = pixelBufferFromCGImage(image.CGImage, size: @rect)
    #     adaptor.appendPixelBuffer(buffer, withPresentationTime:presentTime)
    #   end
    # end
    # writerInput.markAsFinished
    # videoWriter.finishWriting
    # CVPixelBufferPoolRelease(adaptor.pixelBufferPool)
    # ap "DONE"
