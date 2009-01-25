CONFIG = {
  :model => './../../data/scene.mqo',
  :to_meter_ratio => 0.1,

  :cameras => [
    # L building, towards the gym
    {
      :position          => Vector[1, -5, 58],
      :focal_vector      => Vector[0.1, -0.4, -0.5],
      :width             => 0.64,
      :height            => 0.48,
      :segments_per_edge => 20
    },

    # L building, towards the parking
    {
      :position          => Vector[-30, -5, 77],
      :focal_vector      => Vector[-0.1, -0.4, 0.5],
      :width             => 0.64,
      :height            => 0.48,
      :segments_per_edge => 20
    },

    # D building
    {
      :position          => Vector[20, -5, 15],
      :focal_vector      => Vector[-0.5, -0.4, 0],
      :width             => 0.64,
      :height            => 0.48,
      :segments_per_edge => 20
    }
  ]
}
