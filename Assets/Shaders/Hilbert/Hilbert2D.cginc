#ifndef HILBERT_2D_CGINC_
#define HILBERT_2D_CGINC_

#define HILBERT_ORDER 5
// N = 2 ** HILBERT_ORDER
#define N 32
#define CELL_SIZE (1.0 / N)
#define HALF_CELL_SIZE (0.5 * CELL_SIZE)
#define LINE_RADIUS (0.25 * CELL_SIZE)

/**
 * Rotates and flips a quadrant appropriately.
 *
 * @param n the length of a side of the square. Must be a power of 2.
 * @param x [inout] the X coordinate. On return, contains the new coordinate.
 * @param y [inout] the Y coordinate. On return, contains the new coordinate.
 * @param rx whether to reflect in X?
 * @param ry whether _not_ to flip X and Y?
 */
void rot(uint n, inout uint x, inout uint y, bool rx, bool ry)
{
    if (!ry)
    {
        // Reflect
        if (rx)
        {
            x = n - 1 - x;
            y = n - 1 - y;
        }
        // Flip
        int t = x;
        x = y;
        y = t;
    }
}

/**
 * Converts 1D Hilbert coordinate into X-Y Cartesian coordinates.
 *
 * @param d the Hilbert coordinate.
 * @return the Cartesian coordinates.
 */
uint2 d2xy(uint d)
{
    uint2 result = uint2(0, 0);
    uint t = d;
    for (uint s = 1; s < N; s = s * 2)
    {
        bool rx = 1 & (t / 2);
        bool ry = 1 & (t ^ rx);
        rot(s, result.x, result.y, rx, ry);
        result = result + s * uint2(rx, ry);
        t /= 4;
    }
    return result;
}

/**
 * Converts X-Y Cartesian coordinates into a 1D Hilbert coordinate.
 *
 * @param p the Cartesian coordinates.
 * @return the Hilbert coordinate.
 */
uint xy2d(uint2 p)
{
    uint d = 0;
    for (uint s = N / 2; s > 0; s = s / 2)
    {
        bool rx = (p.x & s) > 0;
        bool ry = (p.y & s) > 0;
        d = d + s * s * ((3 * rx) ^ ry);
        rot(s, p.x, p.y, rx, ry);
    }
    return d;
}

float3 centerOfCell(uint2 cell)
{
    return float3((float2) cell * CELL_SIZE + HALF_CELL_SIZE - 0.5, 0.0);
}

float sdHilbert2D(float3 position)
{
    // Figuring out what cell we're in.
    // we convert the -0.5 ~ 0.5 coordinate into cell coordinates.
    // TODO: This should be using some variation on pMod2.
    uint2 cell = (uint2) (clamp(position.xy + 0.5, 0.0, 1.0 - HALF_CELL_SIZE) * N);

    uint h = xy2d(cell);
    float3 cellCenter = centerOfCell(cell);

    float d = sdSphere(position - cellCenter, LINE_RADIUS);
    if (h > 0)
    {
        uint2 cellPrev = d2xy(h - 1);
        d = opU(d, sdCapsule(position, cellCenter, centerOfCell(cellPrev), LINE_RADIUS));
    }
    if (h < (N * N) - 1)
    {
        uint2 cellNext = d2xy(h + 1);
        d = opU(d, sdCapsule(position, cellCenter, centerOfCell(cellNext), LINE_RADIUS));
    }
    return d;
}

#endif // HILBERT_2D_CGINC_