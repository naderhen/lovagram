module FeedCellStylesheet
  def cell_size
    {w: 80, h: 80}
  end

  def feed_cell(st)
    st.frame = cell_size
    st.background_color = color.random
    st.clips_to_bounds = true
  end

  def image(st)
    st.frame = :full
    st.view.contentMode = UIViewContentModeScaleAspectFill
  end

  def check(st)
    st.frame = :full
    st.hidden = true
    st.background_color = color.translucent_black
    st.clips_to_bounds = true
  end

end
