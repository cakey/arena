import Point from "./point"

const CELL_SIZE = 20  // Same as player radius
const PLAYER_RADIUS = 20

// Barrier interface for pathfinding - use same collision as movement
interface PathBarrier {
  circleIntersect(center: Point, radius: number): boolean
}

export interface PathGrid {
  width: number
  height: number
  cells: boolean[][]  // true = walkable, false = blocked
}

// Pathfinding error for debug display
export type PathError = "start_blocked" | "goal_blocked" | "no_path" | null

// Convert world position to grid cell
function toGrid(p: Point): [number, number] {
  return [Math.floor(p.x / CELL_SIZE), Math.floor(p.y / CELL_SIZE)]
}

// Convert grid cell to world position (center of cell)
function toWorld(gx: number, gy: number): Point {
  return new Point(gx * CELL_SIZE + CELL_SIZE / 2, gy * CELL_SIZE + CELL_SIZE / 2)
}

// Check if a cell is blocked by any barrier
function isCellBlocked(gx: number, gy: number, barriers: [PathBarrier, any][]): boolean {
  const cellCenter = toWorld(gx, gy)
  for (const [barrier] of barriers) {
    if (barrier.circleIntersect(cellCenter, PLAYER_RADIUS)) {
      return true
    }
  }
  return false
}

// Find nearest walkable cell using BFS
function findNearestWalkable(startX: number, startY: number, grid: PathGrid, maxRadius: number = 5): [number, number] | null {
  // If already walkable, return it
  if (startX >= 0 && startY >= 0 && startX < grid.width && startY < grid.height && grid.cells[startX]?.[startY]) {
    return [startX, startY]
  }

  // BFS to find nearest walkable cell
  const visited = new Set<string>()
  const queue: [number, number, number][] = [[startX, startY, 0]]  // x, y, distance

  while (queue.length > 0) {
    const [x, y, dist] = queue.shift()!
    const key = `${x},${y}`

    if (visited.has(key) || dist > maxRadius) continue
    visited.add(key)

    // Bounds check
    if (x < 0 || y < 0 || x >= grid.width || y >= grid.height) continue

    // Found walkable cell
    if (grid.cells[x]?.[y]) {
      return [x, y]
    }

    // Add neighbors
    for (let dx = -1; dx <= 1; dx++) {
      for (let dy = -1; dy <= 1; dy++) {
        if (dx === 0 && dy === 0) continue
        queue.push([x + dx, y + dy, dist + 1])
      }
    }
  }

  return null  // No walkable cell found within radius
}

// Generate the pathfinding grid
export function generateGrid(mapSize: Point, barriers: [PathBarrier, any][]): PathGrid {
  const width = Math.ceil(mapSize.x / CELL_SIZE)
  const height = Math.ceil(mapSize.y / CELL_SIZE)
  const cells: boolean[][] = []

  for (let gx = 0; gx < width; gx++) {
    cells[gx] = []
    for (let gy = 0; gy < height; gy++) {
      cells[gx][gy] = !isCellBlocked(gx, gy, barriers)
    }
  }

  return { width, height, cells }
}

// A* pathfinding on the grid
function astarGrid(
  startX: number, startY: number,
  goalX: number, goalY: number,
  grid: PathGrid
): [number, number][] {
  const key = (x: number, y: number) => `${x},${y}`

  const openSet = new Set([key(startX, startY)])
  const cameFrom = new Map<string, [number, number]>()
  const gScore = new Map<string, number>()
  const fScore = new Map<string, number>()

  gScore.set(key(startX, startY), 0)
  fScore.set(key(startX, startY), Math.abs(goalX - startX) + Math.abs(goalY - startY))

  // 8-directional movement
  const neighbors = [
    [-1, -1], [0, -1], [1, -1],
    [-1, 0],          [1, 0],
    [-1, 1],  [0, 1],  [1, 1]
  ]

  while (openSet.size > 0) {
    // Find node with lowest fScore
    let currentKey = ""
    let lowestF = Infinity
    for (const k of openSet) {
      const f = fScore.get(k) ?? Infinity
      if (f < lowestF) {
        lowestF = f
        currentKey = k
      }
    }

    const [cx, cy] = currentKey.split(",").map(Number)

    if (cx === goalX && cy === goalY) {
      // Reconstruct path
      const path: [number, number][] = [[cx, cy]]
      let curr = currentKey
      while (cameFrom.has(curr)) {
        const [px, py] = cameFrom.get(curr)!
        path.unshift([px, py])
        curr = key(px, py)
      }
      return path
    }

    openSet.delete(currentKey)

    for (const [dx, dy] of neighbors) {
      const nx = cx + dx
      const ny = cy + dy

      // Bounds check
      if (nx < 0 || ny < 0 || nx >= grid.width || ny >= grid.height) continue
      // Walkable check
      if (!grid.cells[nx][ny]) continue

      // Diagonal movement: also check adjacent cells to prevent corner cutting
      if (dx !== 0 && dy !== 0) {
        if (!grid.cells[cx + dx][cy] || !grid.cells[cx][cy + dy]) continue
      }

      const moveCost = dx !== 0 && dy !== 0 ? 1.414 : 1  // Diagonal vs cardinal
      const tentativeG = (gScore.get(currentKey) ?? Infinity) + moveCost

      const nKey = key(nx, ny)
      if (tentativeG < (gScore.get(nKey) ?? Infinity)) {
        cameFrom.set(nKey, [cx, cy])
        gScore.set(nKey, tentativeG)
        fScore.set(nKey, tentativeG + Math.abs(goalX - nx) + Math.abs(goalY - ny))
        openSet.add(nKey)
      }
    }
  }

  return []  // No path found
}

// Main pathfinding function - returns { path, error }
export function findPath(from: Point, to: Point, grid: PathGrid, barriers: [PathBarrier, any][]): { path: Point[], error: PathError } {
  const [startX, startY] = toGrid(from)
  const [goalX, goalY] = toGrid(to)

  // Clamp to grid bounds
  const clampedStartX = Math.max(0, Math.min(startX, grid.width - 1))
  const clampedStartY = Math.max(0, Math.min(startY, grid.height - 1))
  const clampedGoalX = Math.max(0, Math.min(goalX, grid.width - 1))
  const clampedGoalY = Math.max(0, Math.min(goalY, grid.height - 1))

  // Same cell - just go directly
  if (clampedStartX === clampedGoalX && clampedStartY === clampedGoalY) {
    return { path: [to], error: null }
  }

  // A* can handle blocked start - it will find walkable neighbors
  // If goal is blocked, find nearest walkable goal
  let adjGoalX = clampedGoalX, adjGoalY = clampedGoalY
  if (!grid.cells[clampedGoalX]?.[clampedGoalY]) {
    const nearest = findNearestWalkable(clampedGoalX, clampedGoalY, grid)
    if (!nearest) {
      return { path: [], error: "goal_blocked" }
    }
    [adjGoalX, adjGoalY] = nearest
  }

  const gridPath = astarGrid(clampedStartX, clampedStartY, adjGoalX, adjGoalY, grid)

  if (gridPath.length === 0) {
    // Couldn't find path - might be completely stuck
    return { path: [], error: "no_path" }
  }

  // Convert to world coordinates and add destination
  const worldPath = gridPath.map(([gx, gy]) => toWorld(gx, gy))
  worldPath.push(to)

  // Skip first point (where we already are)
  return { path: worldPath.slice(1), error: null }
}

// For debug visualization
export function getGridCellSize(): number {
  return CELL_SIZE
}
