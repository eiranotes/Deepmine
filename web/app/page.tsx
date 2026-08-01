import type { Metadata } from "next";
import { MinePrototype } from "./MinePrototype";

export const metadata: Metadata = {
  title: "DeepMine — 연속 갱도 프로토타입",
  description:
    "지층의 가운데를 뚫고 내려가며 장비 강화가 광산에 직접 나타나는 DeepMine 웹 프로토타입",
};

export default function Home() {
  return <MinePrototype />;
}
