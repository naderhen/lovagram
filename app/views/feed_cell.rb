class FeedCell < UICollectionViewCell 
  attr_reader :reused
  attr_accessor :entry, :chosen

  def rmq_build
    rmq(self).apply_style :feed_cell

    rmq(self.contentView).tap do |q|
      @image = q.append(UIImageView, :image).get
      @check = q.append(UIView, :check).get
    end
  end

  def prepareForReuse
    @reused = true
  end

  def update(entry)
    @entry = entry
    @image.url = entry["images"]["low_resolution"]["url"]
  end

  def setChosen(chosen)
    @chosen = chosen
    if @chosen
      rmq(@check).show
    else
      rmq(@check).hide
    end
  end

end
