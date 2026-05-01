// Defines the tools/functions available in Flutter
const tools = [
  {
    "type": "function",
    "function": {
      "name": "draw_circle",
      "description":
          "Draw a circle with a specified radius. If the radius is missing, use 10 as default. If the radius should be random, use a random value between 10 and 25. You can specify the color as a string (e.g., 'red', 'blue', 'green', etc.), stroke width for outline, or gradient colors as an array of strings for a linear gradient fill.",
      "parameters": {
        "type": "object",
        "properties": {
          "x": {"type": "number"},
          "y": {"type": "number"},
          "radius": {"type": "number"},
          "color": {"type": "string"},
          "strokeWidth": {"type": "number"},
          "gradientColors": {
            "type": "array",
            "items": {"type": "string"},
          },
        },
        "required": ["x", "y", "radius"],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "draw_line",
      "description":
          "Draw a line between two points. If positions are not specified, choose random points between x=10, y=10 and x=100, y=100. You can specify the color as a string (e.g., 'red', 'blue', 'green', etc.) and stroke width.",
      "parameters": {
        "type": "object",
        "properties": {
          "startX": {"type": "number"},
          "startY": {"type": "number"},
          "endX": {"type": "number"},
          "endY": {"type": "number"},
          "color": {"type": "string"},
          "strokeWidth": {"type": "number"},
        },
        "required": ["startX", "startY", "endX", "endY"],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "draw_rectangle",
      "description":
          "Draw a rectangle defined by the top-left and bottom-right coordinates. You can specify the color as a string (e.g., 'red', 'blue', 'green', etc.), stroke width for outline, or gradient colors as an array of strings for a linear gradient fill.",
      "parameters": {
        "type": "object",
        "properties": {
          "topLeftX": {"type": "number"},
          "topLeftY": {"type": "number"},
          "bottomRightX": {"type": "number"},
          "bottomRightY": {"type": "number"},
          "color": {"type": "string"},
          "strokeWidth": {"type": "number"},
          "gradientColors": {
            "type": "array",
            "items": {"type": "string"},
          },
        },
        "required": ["topLeftX", "topLeftY", "bottomRightX", "bottomRightY"],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "draw_text",
      "description":
          "Draw a text string at a specified position. You can specify the color as a string (e.g., 'red', 'blue', 'green', etc.), font size, font weight (e.g., 'bold', 'normal', 'light'), and font style (e.g., 'italic', 'normal').",
      "parameters": {
        "type": "object",
        "properties": {
          "text": {"type": "string"},
          "x": {"type": "number"},
          "y": {"type": "number"},
          "color": {"type": "string"},
          "fontSize": {"type": "number"},
          "fontWeight": {"type": "string"},
          "fontStyle": {"type": "string"},
        },
        "required": ["text", "x", "y"],
      },
    },
  },
];
