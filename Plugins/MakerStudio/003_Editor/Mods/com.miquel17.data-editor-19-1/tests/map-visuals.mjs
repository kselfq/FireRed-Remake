import assert from "node:assert/strict";
import { layoutConnectionWorld, relativeMapPlacement } from "../src/world/map_visuals.js";

const info = (id) => ({ id, width: id === 2 ? 6 : 10, height: id === 2 ? 5 : 8, tilesetId: 1 });

assert.deepEqual(
  relativeMapPlacement({ directionA: "E", offsetA: 2, directionB: "W", offsetB: 4 }, info(1), info(2)),
  { x: 10, y: -2 },
  "east/west connections must align the two edge offsets",
);
assert.deepEqual(
  relativeMapPlacement({ directionA: "N", offsetA: 3, directionB: "S", offsetB: 1 }, info(1), info(2)),
  { x: 2, y: -5 },
  "north/south connections must place the target above the source",
);
assert.deepEqual(
  relativeMapPlacement({ directionA: 7, offsetA: 9, directionB: 2, offsetB: 3 }, info(1), info(2)),
  { x: 5, y: 6 },
  "coordinate connections must align the selected tile pair",
);

const connections = [
  { mapA: 1, directionA: "E", offsetA: 0, mapB: 2, directionB: "W", offsetB: 0 },
  { mapA: 2, directionA: "S", offsetA: 2, mapB: 3, directionB: "N", offsetB: 2 },
  { mapA: 10, directionA: "S", offsetA: 0, mapB: 11, directionB: "N", offsetB: 0 },
];
const world = layoutConnectionWorld(connections, info);
assert.equal(world.positions.size, 5, "the atlas must include every map that participates in a connection");
assert.equal(world.components.length, 2, "disconnected connection groups must remain separate components");
for (const [mapId, position] of world.positions) {
  assert.ok(Number.isFinite(position.x) && Number.isFinite(position.y), "map " + mapId + " must receive a finite atlas position");
  assert.ok(position.x >= 0 && position.y >= 0, "map " + mapId + " must be packed inside the positive atlas canvas");
}
const componentBoxes = world.components.map((component) => {
  const nodes = component.nodes.map((id) => ({ position: world.positions.get(id), info: info(id) }));
  return {
    left: Math.min(...nodes.map((node) => node.position.x)),
    top: Math.min(...nodes.map((node) => node.position.y)),
    right: Math.max(...nodes.map((node) => node.position.x + node.info.width)),
    bottom: Math.max(...nodes.map((node) => node.position.y + node.info.height)),
  };
});
const overlap = componentBoxes[0].left < componentBoxes[1].right
  && componentBoxes[0].right > componentBoxes[1].left
  && componentBoxes[0].top < componentBoxes[1].bottom
  && componentBoxes[0].bottom > componentBoxes[1].top;
assert.equal(overlap, false, "disconnected components must be packed without overlap");

console.log("Map placement and full-atlas layout tests passed.");
