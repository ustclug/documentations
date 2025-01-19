#!/usr/bin/env python3

import inspect
import os

import material


CUSTOM_ADMONITIONS = {
    "homepage-workflow": {
        "icon": "fontawesome/solid/wrench",
        "rgb": (241, 79, 33),
    },
    "homepage-infrastructure": {
        "icon": "material/toy-brick",
        "rgb": (126, 185, 0),
    },
    "homepage-services": {
        "icon": "fontawesome/solid/certificate",
        "rgb": (0, 163, 238),
    },
    "homepage-faq": {
        "icon": "fontawesome/solid/circle-question",
        "rgb": (254, 184, 0),
    },
}

# ensure we're in project root directory
if not os.path.isfile("mkdocs.yml"):
    raise FileNotFoundError("mkdocs.yml not found")


material_root = os.path.dirname(inspect.getfile(material))
material_root = os.path.join(material_root, "templates", ".icons")


def get_icon(name):
    with open(os.path.join(material_root, name + ".svg")) as f:
        return f.read()


root_defs = []
typeset_defs = []
for name, data in CUSTOM_ADMONITIONS.items():
    varname = f"--md-admonition-icon--{name}"
    content = get_icon(data["icon"])
    s = f"  {varname}: url('data:image/svg+xml;charset=utf-8,{content}');"
    root_defs.append(s)

    rgb = data["rgb"]
    rgb_s = f"{rgb[0]}, {rgb[1]}, {rgb[2]}"
    s = f"""
  .admonition.{name},
  details.{name} {{
    border-color: rgb({rgb_s});
  }}

  .{name} > .admonition-title,
  .{name} > summary {{
    background-color: rgba({rgb_s}, 0.1);

    &::before {{
      background-color: rgb({rgb_s});
      -webkit-mask-image: var({varname});
              mask-image: var({varname});
    }}
  }}""".lstrip("\n")
    typeset_defs.append(s)

with open("docs/css/admonitions.scss", "w") as f:
    print(":root {", file=f)
    print("\n".join(root_defs), file=f)
    print("}", file=f, end="\n\n")

    print(".md-typeset {", file=f)
    print("\n\n".join(typeset_defs), file=f)
    print("}", file=f)
