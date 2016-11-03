/* Lone Wolf Team */

//something that takes the size and rules as arguments
//initialize array of initial conditions

//generate outer

//generate inner  (2D)

//main loop walks through outer automater, gets the inner cell and passes that to another fxn that decides what do do with it

/*
Things to decide:
- Do we want to have a fixed set of the inner oscillators? So for example we could
just store them in an array organized by period, or is there some way of generating them?

- What to do about edges? In the generation of the grids we can either ignore the edge values
that don't have all 3 neighbors and leave them as 0, fill in the missing neighbors with some
default value, or treat the grid cyclically and so the leftmost cell is neighbors with the
rightmost cell.

- How to interpret musically. Inner cells map to samples + index? Rows and columns in outer
grid mean pitch information or period?

- What to do when an inner cell is reached? Some options:
-- Stop moving in the outer grid, play until inner cell repeats
-- Keep moving in the outer grid, play the inner cell until a new one is reached and then
--- Stop the old one and play the new
--- Layer the new one with the old (up to some limit?)
-- If no new cell is reached, keep playing last one (ones?) or allow silence
*/

// Run this section to see examples
(
// Creates the outer grid given the number of rows, columns, rule set,
// and the initial row
var makeOuter = {|nrows, ncols, rules, init|
    var grid;

    // Create an array of 0s
    grid = Array.fill2D(nrows, ncols, 0);

    // Set the first row
    grid[0] = init;

    (1 .. nrows - 1).do {|rowIdx| // For each row (skipping the first)...
        (1 .. ncols - 2).do {|colIdx| // For each column (ignoring the edges)...
            // Maybe we want to do cyclic borders instead of ignoring the edges?
            // Or just treat the values off the edge as 0 or some other default?

            // Get the list of neighbors (right now just the on the row above)
            var neighbors = grid[rowIdx - 1][colIdx - 1 .. colIdx + 1];

            // Apply the rules to get the new value
            grid[rowIdx][colIdx] = rules.value(neighbors);
        };
    };

    // Return the grid
    grid;
};

// Applies the Game of Life rules nsteps times to the given grid
var stepInner = {|oldGrid, nsteps = 1|
    var grid, tempGrid;

    // Copy the old grid so we don't change it
    grid = oldGrid.deepCopy;

    // Create a temporary grid to apply changes to until all cells are updated
    tempGrid = grid.deepCopy;

    nsteps.do { // Apply the rules nsteps times
        (1 .. grid.size - 2).do {|rowIdx| // For each row (ignoring the edges)...
            (1 .. grid[rowIdx].size - 2).do {|colIdx| // For each column (ignoring the edges)...
                // Get the list of neighbors (all 8 surrounding cells)
                var neighbors = [
                    grid[rowIdx - 1][colIdx - 1 .. colIdx + 1],
                    grid[rowIdx][colIdx - 1], grid[rowIdx][colIdx + 1],
                    grid[rowIdx + 1][colIdx - 1 .. colIdx + 1]
                ].flat;

                // Apply the rules to get the new value in the temp grid
                tempGrid[rowIdx][colIdx] = gameOfLife.value(neighbors, grid[rowIdx][colIdx]);
            };
        };

        // Copy changes from temp grid now that all cells are updated
        grid = tempGrid.deepCopy;
    };

    // Return the new grid
    grid;
};

// Conway's Game of Life rules (used for the inner grids)
var gameOfLife = {|in, curVal|
    var out;

    out = if (curVal == 0,
        { // Dead
            if (in.sum == 3, { 1; }, { 0; });
        },
        { // Live
            if (in.sum == 2 || (in.sum == 3), { 1; }, { 0; });
        }
    );

    out;
};

// Wolfram's rule 30 (included just as an example)
var rule30 = {|in|
    var out;

    out = case
    {in == [1, 1, 1]} {0}
    {in == [1, 1, 0]} {0}
    {in == [1, 0, 1]} {0}
    {in == [1, 0, 0]} {1}
    {in == [0, 1, 1]} {1}
    {in == [0, 1, 0]} {1}
    {in == [0, 0, 1]} {1}
    {in == [0, 0, 0]} {0};

    out;
};

// A simple non-binary rule (included just as an example)
var sampleRule = {|in|
    var out;

    out = if (in.sum.even,
        { 2; },
        { (in.first + in.last) % 4; }
    );

    out;
};

// Example using rule 30
~ncols = 50;
~nrows = 20;
~init = Array.fill(~ncols, 0);
~init[~ncols / 2] = 1;
~grid = makeOuter.value(~nrows, ~ncols, rule30, ~init);
~grid.do {|row|
    row.join.postln;
};

"".postln;

// Example using a rule with value from 0-3
~ncols = 50;
~nrows = 20;
~init = Array.fill(~ncols, { 4.rand; });
~grid = makeOuter.value(~nrows, ~ncols, sampleRule, ~init);
~grid.do {|row| row.join.postln; };

"".postln;

// Example of a few steps of an oscillating inner cell
~grid = [
    [0,0,0,0,0,0],
    [0,0,0,0,0,0],
    [0,0,1,1,1,0],
    [0,1,1,1,0,0],
    [0,0,0,0,0,0],
    [0,0,0,0,0,0]
];
"Initial".postln;
~grid.do {|row| row.join.postln; };

4.do {|i|
    ("Step" + (i + 1)).postln;
    ~grid = stepInner.value(~grid);
    ~grid.do {|row| row.join.postln; };
};
);