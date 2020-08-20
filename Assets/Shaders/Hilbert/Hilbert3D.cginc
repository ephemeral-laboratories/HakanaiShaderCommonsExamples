#ifndef HILBERT_3D_CGINC_
#define HILBERT_3D_CGINC_

// 3D Hilbert curve mappings.
// Derived from https://github.com/ryan-williams/hilbert-js

#define HILBERT_ORDER 4
#define LOG2_PARITY (HILBERT_ORDER % 3)
// N = 2 ** HILBERT_ORDER
#define N 16
#define CELL_SIZE (1.0 / N)
#define HALF_CELL_SIZE (0.5 * CELL_SIZE)
#define LINE_RADIUS (0.25 * CELL_SIZE)

static const uint d2horseshoe[8] = {0, 1, 3, 2, 6, 7, 5, 4};
static const uint horseshoe2d[8] = {0, 1, 3, 2, 7, 6, 4, 5};

/**
 * Calculates a single integer value from the given bits.
 *
 * @param regs bits formed from the coordinate being computed.
 * @return a unique value from 0..7 calculated from the bits.
 */
uint calcIndex(bool3 regs)
{
    return dot(regs, uint3(1, 2, 4));
}

/**
 * Rotates the point appropriately for the given `n` and `regs`.
 *
 * @param p the point to rotate.
 * @param regs bits formed from the coordinate being computed.
 * @param n the coordinate into the part of the Hilbert curve currently being calculated?
 * @return the rotated point.
 */
uint3 rotate(uint3 p, bool3 regs, uint n)
{
    switch (calcIndex(regs))
    {
        case 0:
            return p.zxy;
        case 1:
        case 3:
            return p.yzx;
        case 2:
        case 6:
            return uint3(n - p.x, n - p.y, p.z);
        case 5:
        case 7:
            return uint3(p.y, n - p.z, n - p.x);
        default: // 4
            return uint3(n - p.z, p.x, n - p.y);
    }
}

/**
 * Performs the inverse of `rotate`.
 *
 * @param p the point to rotate.
 * @param regs bits formed from the coordinate being computed.
 * @param n the coordinate into the part of the Hilbert curve currently being calculated?
 * @return the rotated point.
 */
uint3 unrotate(uint3 p, bool3 regs, uint n)
{
    switch (calcIndex(regs))
    {
        case 0:
            return p.yzx;
        case 1:
        case 3:
            return p.zxy;
        case 2:
        case 6:
            return uint3(n - p.x, n - p.y, p.z);
        case 5:
        case 7:
            return uint3(n - p.z, p.x, n - p.y);
        default: // 4
            return uint3(p.y, n - p.z, n - p.x);
    }
}

/**
 * Swizzles the given point to rotate the coordinates `n` places to the left.
 *
 * @param p the point.
 * @param n the number of places to rotate.
 * @return the swizzled point.
 */
uint3 rotateLeft(uint3 p, uint n)
{
    switch (n % 3)
    {
        case 0: return p;
        case 1: return p.yzx;
        default: return p.zxy;
    }
}

/**
 * Swizzles the given point to rotate the coordinates `n` places to the right.
 *
 * @param p the point.
 * @param n the number of places to rotate.
 * @return the swizzled point.
 */
uint3 rotateRight(uint3 p, uint n)
{
    switch (n % 3)
    {
        case 0: return p;
        case 1: return p.zxy;
        default: return p.yzx;
    }
}

/**
 * Converts 1D Hilbert coordinate into X-Y-Z Cartesian coordinates.
 *
 * @param d the Hilbert coordinate.
 * @return the Cartesian coordinates.
 */
uint3 d2xyz(uint d)
{
    uint3 p;
    uint s = 1;
    uint iter = 2;
    while (d > 0 || s < N)
    {
        bool xBit = d & 1;
        bool yBit = (d >> 1) & 1;
        bool zBit = (d >> 2) & 1;
        bool3 regs = bool3(xBit ^ yBit, yBit ^ zBit, zBit);
        p = rotate(p, regs, s - 1) + regs * s;

        d = d >> 3;
        s <<= 1;
        iter++;
    }
    p = rotateLeft(p, iter - LOG2_PARITY + 1);
    return p; // TODO: return p.shuffle(this.reverseAnchorAxisOrder);
};

/**
 * Converts X-Y-Z Cartesian coordinates into a 1D Hilbert coordinate.
 *
 * @param p the Cartesian coordinates.
 * @return the Hilbert coordinate.
 */
uint xyz2d(uint3 p)
{
    uint s = 1;
    uint level = 0;
    uint pMax = max(p.x, max(p.y, p.z));
    for (; (s << 1) <= pMax; s <<= 1)
    {
        level = (level + 1) % 3;
    }

    // TODO: p = p.shuffle(this.anchorAxisOrder);
    p = rotateRight(p, level - LOG2_PARITY + 1);

    uint d = 0;
    while (s > 0)
    {
        bool3 regs = (bool3) (p & s);

        d *= 8;
        d += horseshoe2d[calcIndex(regs)];

        level = (level + 2) % 3;
        p = p % s;
        p = unrotate(p, regs, s - 1);
        s = s >> 1;
    }

    return d;
};

float3 centerOfCell(uint3 cell)
{
    return (float3) cell * CELL_SIZE + HALF_CELL_SIZE - 0.5;
}

float sdHilbert3D(float3 position)
{
    // Figuring out what cell we're in.
    // we convert the -0.5 ~ 0.5 coordinate into cell coordinates.
    // TODO: This should be using some variation on pMod3.
    uint3 cell = (uint3) (clamp(position + 0.5, 0.0, 1.0 - HALF_CELL_SIZE) * N);

    uint h = xyz2d(cell);
    float3 cellCenter = centerOfCell(cell);

    float d = MAX_DISTANCE * 2.0;
    if (h > 0)
    {
        uint3 cellPrev = d2xyz(h - 1);
        d = opU(d, sdCapsule(position, cellCenter, centerOfCell(cellPrev), LINE_RADIUS));
    }
    if (h < (N * N * N) - 1)
    {
        uint3 cellNext = d2xyz(h + 1);
        d = opU(d, sdCapsule(position, cellCenter, centerOfCell(cellNext), LINE_RADIUS));
    }
    return d;
}

#endif // HILBERT_3D_CGINC_