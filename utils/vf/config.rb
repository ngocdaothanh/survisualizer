GROUND_HEIGHT = -16  # m

CONFIG = {
  :model => './../../data/scene.mqo',
  :to_meter_ratio => 0.1,

  :segments_per_edge => 20,
  :cameras => [
    # L building, towards the gym
    # {
    #       :position => [1, 5 - ORIGIN_HEIGHT, 58.2],
    #       :focus    => [0.1, -0.4, -0.5],
    #       :width    => 0.64,
    #       :height   => 0.48
    #     },

    # L building, towards the parking
    {
      :position => [-20, GROUND_HEIGHT + 9, 76.2],
      :focus    => [-0.15, -0.3, 0.4],
      :width    => 0.64,
      :height   => 0.48
    },

    # D building
    # {
    #       :position => [22.6, 5 - ORIGIN_HEIGHT, 14],
    #       :focus    => [-0.5, -0.4, 0],
    #       :width    => 0.64,
    #       :height   => 0.48
    #     }
  ]
}
