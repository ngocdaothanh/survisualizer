CONFIG = {
  :window_width  => 640,
  :window_height => 480,
  :fullscreen    => false,

  :model => './data/scene.mqo',

  :cameras => [
    {
      :position          => Vector[0, 0.3, -15],
      :focal_vector      => Vector[0.6, -0.4, -0.1],
      :width             => 0.64,
      :height            => 0.48,
      :segments_per_edge => 20,
      :visualizer        => VectorVisualizer
    },
    {
      :position          => Vector[0.5, 0.5, -10],
      :focal_vector      => Vector[-0.5, -0.4, -0.4],
      :width             => 0.64,
      :height            => 0.48,
      :segments_per_edge => 20,
      :visualizer        => GridVisualizer
    }
  ]
}
