CONFIG = {
  :window_width  => 640,
  :window_height => 480,

  :model => 'scene',

  :cameras => [
    {
      :position     => Vector[0, 0.5, -15],
      :focal_vector => Vector[0.5, -0.3, 0.5],
      :width        => 0.64,
      :height       => 0.48,
      :visualizer   => AnimationVisualizer
    },
    {
      :position     => Vector[0.5, 0.5, -10],
      :focal_vector => Vector[-0.5, -0.4, 0.1],
      :width        => 0.64,
      :height       => 0.48,
      :visualizer   => VectorVisualizer
    }
  ]
}
