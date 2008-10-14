CONFIG = {
  :window_width  => 640,
  :window_height => 480,

  :cameras => [
    {
      :position     => Vector[0, 5, -5],
      :focal_vector => Vector[1, -0.5, 1],
      :width        => 0.64,
      :height       => 0.48,
      :visualizer   => AnimationVisualizer
    },
    {
      :position     => Vector[-0.1, 5, -2],
      :focal_vector => Vector[-0.5, -0.5, -0.5],
      :width        => 0.64,
      :height       => 0.48,
      :visualizer   => VectorVisualizer
    }
  ]
}
