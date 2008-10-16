CONFIG = {
  :window_width  => 640,
  :window_height => 480,

  :model => 'scene',

  :cameras => [
    {
      :position     => Vector[0, 2, -5],
      :focal_vector => Vector[1, -0.5, 1],
      :width        => 0.64,
      :height       => 0.48,
      :visualizer   => AnimationVisualizer
    },
    {
      :position     => Vector[-0.1, 2, -2],
      :focal_vector => Vector[-0.5, -0.5, -0.5],
      :width        => 0.64,
      :height       => 0.48,
      :visualizer   => VectorVisualizer
    }
  ]
}
