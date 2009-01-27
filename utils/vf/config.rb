CONFIG = {
  :model => './../../data/scene.mqo',
  :to_meter_ratio => 0.1,

  :segments_per_edge => 20,
  :cameras => [
    # L building, towards the gym
    {
      :position => [1, -5, 58],
      :focus    => [0.1, -0.4, -0.5],
      :width    => 0.64,
      :height   => 0.48
    },

    # L building, towards the parking
    {
      :position => [-30, -5, 77],
      :focus    => [-0.1, -0.4, 0.5],
      :width    => 0.64,
      :height   => 0.48
    },

    # D building
    {
      :position => [20, -5, 15],
      :focus    => [-0.5, -0.4, 0],
      :width    => 0.64,
      :height   => 0.48
    }
  ]
}
