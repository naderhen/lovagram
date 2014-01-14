class FeedCell < UICollectionViewCell 
  attr_reader :reused
  attr_accessor :entry

  def rmq_build
    rmq(self).apply_style :feed_cell

    rmq(self.contentView).tap do |q|
      @image = q.append(UIImageView, :image).get
    end
  end

  def prepareForReuse
    @reused = true
  end

  def update(entry)
    @entry = entry
    @image.url = entry["images"]["low_resolution"]["url"]
  end

end
