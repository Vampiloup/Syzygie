components {
  id: "Star_Screen"
  component: "/main/Star_Screen/Star_Screen.script"
}
components {
  id: "Fond_pixel_1"
  component: "/Sprites/GUI/Fond_pixel.sprite"
}
components {
  id: "Fond_pixel_2"
  component: "/Sprites/GUI/Fond_pixel.sprite"
}
components {
  id: "Fond_pixel_3"
  component: "/Sprites/GUI/Fond_pixel.sprite"
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_TRIGGER\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"Gui\"\n"
  "mask: \"Curseur\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "    id: \"my_box\"\n"
  "  }\n"
  "  data: 500.0\n"
  "  data: 500.0\n"
  "  data: 50.0\n"
  "}\n"
  ""
}
