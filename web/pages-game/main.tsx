import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { MinePrototype } from "../app/MinePrototype";
import "../app/globals.css";

const root = document.getElementById("root");

if (root === null) {
  throw new Error("DeepMine root element is missing");
}

createRoot(root).render(
  <StrictMode>
    <MinePrototype />
  </StrictMode>,
);
