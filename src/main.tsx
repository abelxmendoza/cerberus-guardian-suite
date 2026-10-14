import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { Cerberus } from "./pages/Cerberus";
import "./styles/cerberus.css";

const root = document.getElementById("root");
if (!root) {
  throw new Error("Root element missing");
}

createRoot(root).render(
  <StrictMode>
    <Cerberus />
  </StrictMode>,
);
