import Point from "./point"
import type { Rect } from "./mechanics/barriers"

const CELL_SIZE = 30  // Grid cell size in pixels
const PLAYER_RADIUS = 20  // Player collision radius

export interface PathGrid {
  width: number
  height: number
  cells: boolean[][]  // true = walkable, false = blocked
}

// Convert world position to grid cell
function toGrid(p: Point): [number, number] {
  return [Math.floor(p.x / CELL_SIZE), Math.floor(p.y / CELL_SIZE)]
}

// Convert grid cell to world position (center of cell)
function toWorld(gx: number, gy: number): Point {
  return new Point(gx * CELL_SIZE + CELL_SIZE / 2, gy * CELL_SIZE + CELL_SIZE / 2)
}

// Check if a cell is blocked by any barrier (with player radius padding)
function isCellBlocked(gx: number, gy: number, barriers: [Rect, any][]): boolean {
  const cellCenter = toWorld(gx, gy)
  // Just use player radius - the cell grid already provides some buffer
  const padding = PLAYER_RADIUS

  for (const [barrier] of barriers) {
    // Expand barrier by padding and check if cell center is inside
    const expandedTL = new Point(barrier.topleft.x - padding, barrier.topleft.y - padding)
    const expandedBR = new Point(barrier.bottomright.x + padding, barrier.bottomright.y + padding)
    if (cellCenter.inside(expandedTL, expandedBR)) {
      return true
    }
  }
  return false
}

// Generate the pathfinding grid
export function generateGrid(mapSize: Point, barriers: [Rect, any][]): PathGrid {
  const width = Math.ceil(mapSize.x / CELL_SIZE)
  const height = Math.ceil(mapSize.y / CELL_SIZE)
  const cells: boolean[][] = []

  let blockedCount = 0
  for (let gx = 0; gx < width; gx++) {
    cells[gx] = []
    for (let gy = 0; gy < height; gy++) {
      cells[gx][gy] = !isCellBlocked(gx, gy, barriers)
      if (!cells[gx][gy]) blockedCount++
    }
  }

  console.log(`Generated ${width}x${height} grid with ${blockedCount} blocked cells`)
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

// Smooth the path by removing unnecessary waypoints
function smoothPath(path: Point[], barriers: [Rect, any][]): Point[] {
  if (path.length <= 2) return path

  const result: Point[] = [path[0]]

  for (let i = 1; i < path.length - 1; i++) {
    const prev = result[result.length - 1]
    const next = path[i + 1]

    // Check if we can skip this waypoint (direct line to next)
    let canSkip = true
    const steps = Math.ceil(prev.distance(next) / (CELL_SIZE / 2))
    for (let s = 0; s <= steps; s++) {
      const t = s / steps
      const testPoint = new Point(
        prev.x + (next.x - prev.x) * t,
        prev.y + (next.y - prev.y) * t
      )
      const [gx, gy] = toGrid(testPoint)
      // Bounds check before accessing grid
      if (gx < 0 || gy < 0) {
        canSkip = false
        break
      }
      // Check if point is inside any expanded barrier
      for (const [barrier] of barriers) {
        const expandedTL = new Point(barrier.topleft.x - PLAYER_RADIUS, barrier.topleft.y - PLAYER_RADIUS)
        const expandedBR = new Point(barrier.bottomright.x + PLAYER_RADIUS, barrier.bottomright.y + PLAYER_RADIUS)
        if (testPoint.inside(expandedTL, expandedBR)) {
          canSkip = false
          break
        }
      }
      if (!canSkip) break
    }

    if (!canSkip) {
      result.push(path[i])
    }
  }

  result.push(path[path.length - 1])
  return result
}

// Main pathfinding function
export function findPath(from: Point, to: Point, grid: PathGrid, barriers: [Rect, any][]): Point[] {
  const [startX, startY] = toGrid(from)
  const [goalX, goalY] = toGrid(to)

  // Bounds check
  if (startX < 0 || startY < 0 || startX >= grid.width || startY >= grid.height) return [to]
  if (goalX < 0 || goalY < 0 || goalX >= grid.width || goalY >= grid.height) return [to]

  // If start or goal is blocked, try to find nearest walkable cell
  if (!grid.cells[startX]?.[startY] || !grid.cells[goalX]?.[goalY]) {
    return [to]  // Fallback to direct
  }

  // Same cell - just go directly
  if (startX === goalX && startY === goalY) {
    return [to]
  }

  const gridPath = astarGrid(startX, startY, goalX, goalY, grid)

  console.log(`Path from (${startX},${startY}) to (${goalX},${goalY}): ${gridPath.length} cells`, gridPath.slice(0, 5))

  if (gridPath.length === 0) {
    console.log("No path found!")
    return [to]  // No path found, try direct
  }

  // Convert to world coordinates (skip smoothing for now to debug)
  const worldPath = gridPath.map(([gx, gy]) => toWorld(gx, gy))

  // Add actual destination at the end
  worldPath.push(to)

  // Skip first point if it's where we already are
  return worldPath.slice(1)
}

// For debug visualization - export grid info
export function getGridCellSize(): number {
  return CELL_SIZE
}

// Legacy exports for compatibility
export interface Waypoint {
  p: Point
  neighbors: number[]
}

export function generateWaypoints(): Waypoint[] {
  return []  // No longer used
}
