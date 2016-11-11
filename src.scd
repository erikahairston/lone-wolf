/* Team Lone Wolf Project */

// Samples
// Run this once
(
// File names of samples
var sampleNames = ["Helplessness Sample.wav", "Ooo Sample.wav", "Dmm Sample.wav", "Free Sample.wav"];

// Array of sample buffers
~samples = Array.fill(sampleNames.size, {|idx|
    Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ sampleNames[idx]);
});

SynthDef(\samplePlayer, {|out = 0, bufnum = 0, rate = 1, left = 0|
    var buf = PlayBuf.ar(
        2,
        bufnum,
        rate * BufRateScale.kr(bufnum),
        doneAction: 2
    );

    Out.ar(out, [buf * left, buf * ((left + 1) % 2)]);
}).add;
)

// Play this section
(
// A collection of periodic 2D cellular automata indexed by their period
var innerGrids = (
    1: [
        [ // Block
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,1,1,0,0,0,0],
            [0,0,0,1,1,0,0,0,0],
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0]
        ],
        [ // Bee hat
            [0,0,0,0,0,0,0,0,0],
            [0,0,1,1,0,0,0,0,0],
            [0,1,0,0,1,0,0,0,0],
            [0,0,1,1,0,1,0,0,0],
            [0,0,0,1,0,1,0,0,0],
            [0,1,0,1,0,1,1,0,0],
            [0,1,1,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0]
        ]
    ],
    2: [
        [ // Blinker
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,1,1,1,0,0,0],
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0]
        ]
        ,
        [ // Bipole
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,1,1,0,0],
            [0,0,0,0,1,0,1,0,0],
            [0,0,0,0,0,0,0,0,0],
            [0,0,1,0,1,0,0,0,0],
            [0,0,1,1,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0]
        ]
    ],
    3: [
        [ // Caterer
            [0,0,0,1,0,0,0,0,0],
            [0,1,0,0,0,1,1,1,1],
            [0,1,0,0,0,1,0,0,0],
            [0,1,0,0,0,0,0,0,0],
            [0,0,0,0,1,0,0,0,0],
            [0,0,1,1,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0,0]
        ],
        [ // Six Ls
            [0,0,0,0,1,0,0,0,0],
            [0,0,1,1,1,0,0,1,0],
            [0,1,0,0,0,1,1,1,0],
            [0,1,1,1,0,0,0,0,0],
            [0,0,0,0,0,1,1,1,0],
            [0,1,1,1,0,0,0,1,0],
            [0,1,0,0,1,1,1,0,0],
            [0,0,0,0,1,0,0,0,0]
        ]
    ],
    5: [
        [ // Octagon
            [0,0,0,0,0,0,0,0,0],
            [0,0,1,0,0,1,0,0,0],
            [0,1,0,1,1,0,1,0,0],
            [0,0,1,0,0,1,0,0,0],
            [0,0,1,0,0,1,0,0,0],
            [0,1,0,1,1,0,1,0,0],
            [0,0,1,0,0,1,0,0,0],
            [0,0,0,0,0,0,0,0,0]
        ],
        [ // Fumarole
            [0,0,0,0,0,0,0,0,0],
            [0,0,0,1,1,0,0,0,0],
            [0,1,0,0,0,0,1,0,0],
            [0,1,0,0,0,0,1,0,0],
            [0,1,0,0,0,0,1,0,0],
            [0,0,1,0,0,1,0,0,0],
            [1,0,1,0,0,1,0,1,0],
            [1,1,0,0,0,0,1,1,0]
        ]
    ]
);

// A rule to generate the outer grid
var innerChoiceRule = {|in|
    var inPeriods, inIdxs;
    var outPeriod, outIdx;

    # inPeriods, inIdxs = in.flop;

    outPeriod = [innerGrids.keys.asList, 0].flat.choose;

    outIdx = if (outPeriod != 0,
        { innerGrids[outPeriod].size.rand; },
        { 0; }
    );

    [outPeriod, outIdx];
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

// Create the outer grid given the number of rows, columns, rule set,
// and the initial row
var makeOuter = {|nrows, ncols, rules, init|
    var grid;

    // Create an array of 0s
    grid = Array.fill2D(nrows, ncols, 0);

    // Set the first row
    grid[0] = init;

    (1 .. nrows - 1).do {|rowIdx| // For each row (skipping the first)...
        (0 .. ncols - 1).do {|colIdx| // For each column
            // Get the list of neighbors
            var neighbors = [
                grid[rowIdx - 1].wrapAt(colIdx - 1),
                grid[rowIdx - 1].wrapAt(colIdx),
                grid[rowIdx - 1].wrapAt(colIdx + 1),

            ];

            // Apply the rules to get the new value
            grid[rowIdx][colIdx] = rules.value(neighbors);
        };
    };

    // Return the grid
    grid;
};

// Apply the Game of Life rules nsteps times to the given grid
var stepInner = {|oldGrid, nsteps = 1|
    var grid, tempGrid;

    // Copy the old grid so we don't change it
    grid = oldGrid.deepCopy;

    // Create a temporary grid to apply changes to until all cells are updated
    tempGrid = grid.deepCopy;

    nsteps.do { // Apply the rules nsteps times
        (0 .. grid.size - 1).do {|rowIdx| // For each row
            (0 .. grid[rowIdx].size - 1).do {|colIdx| // For each column
                var prevRow, nextRow, neighbors;

                // Assume edges are surrounded by 0
                prevRow = grid[rowIdx - 1] ? (0 ! grid[rowIdx].size);
                nextRow = grid[rowIdx + 1] ? (0 ! grid[rowIdx].size);

                // Get the list of neighbors (all 8 surrounding cells)
                neighbors = [
                    prevRow[colIdx - 1] ? 0, prevRow[colIdx], prevRow[colIdx + 1] ? 0,
                    grid[rowIdx][colIdx - 1] ? 0, grid[rowIdx][colIdx + 1] ? 0,
                    nextRow[colIdx - 1] ? 0, nextRow[colIdx], nextRow[colIdx + 1] ? 0
                ];

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

// Decide how long to wait before moving to a new outer cell
// using a Markov chain
var getDelay = {|oldDelay|
    var delayTbl, allDelays;

    // All of the possible delays
    allDelays = [1, 1/2, 1/4, 1/8];

    // Map delays to probability arrays
    delayTbl = (
        1: [4, 2, 2, 1],
        1/2: [2, 4, 3, 2],
        1/4: [1, 2, 4, 3],
        1/8: [1, 2, 2, 4]
    );

    // Choose a delay using the probabilities
    allDelays.wchoose(delayTbl[oldDelay].normalizeSum);
};

// Handle interpreting and playing the inner grid
var playInner = {|grid|
    var pattern, seed, tuning, pitch, pitchRatio, restChance;

    pattern = List[];
    seed = [0, 1, 4, 5, 7, 11, 12, 16];
    tuning = Tuning.et12;
    restChance = 0.9;

    grid.do {|row, rIdx|
        row.do {|value, cIdx|
            if (value == 1,
                {
                    // Compute the ratio to play the buffer at in order to shift it by the given
                    // pitch class
                    pitch = seed.wrapAt(cIdx);
                    pitchRatio = tuning.ratios.wrapAt(pitch) * (pitch.div(tuning.ratios.size) + 1);

                    // Play samples 1-4 in either the left or right channel
                    // Some notes will be rests to reduce the density of notes
                    pattern.add(Pbind(
                        \instrument, \samplePlayer,
                        \bufnum, ~samples.wrapAt(rIdx % 4),
                        \rate, pitchRatio,
                        \left, (rIdx < 4).asInt,
                        \type, Pwrand([\note, \rest], [1 - restChance, restChance], inf)
                    ));
                }
            );
        };
    };

    // Wrap multiple Pbind's into a single pattern to be played together
    Ppar(pattern);
};

// Create the grids and walk around it in a loop
var playSong = {|duration = inf|
    var curX, curY;
    var outGrid, outRows, outCols, outRules, outInit;
    var inRows, inCols, maxPlaying, playing;
    var outDisplay, inDisplays, gridSize;
    var play;

    // Initialize the outer grid
    outRows = 40;
    outCols = 40;
    outRules = innerChoiceRule;
    outInit = Array.fill(outCols, {
        var period, idx;
        period = innerGrids.keys.choose;
        idx = innerGrids[period].size.rand;
        [period, idx];
    });
    outGrid = makeOuter.value(outRows, outCols, outRules, outInit);

    inRows = innerGrids.choose.choose.size;
    inCols = innerGrids.choose.choose[0].size;
    maxPlaying = 3;

    // Initialize the coordinates
    curX = outCols.rand;
    curY = outRows.rand;

    // Initialize the outer display
    gridSize = 15;
    outDisplay = Window(
        "Outer Grid", Rect(300, 100, outCols * gridSize, outRows * gridSize), false
    ).front;
    outDisplay.view.background = Color.white;

    outDisplay.drawFunc = {
        var rect;

        outRows.do {|row|
            // Draw the current position in red, all else in black
            outCols.do {|col|
                Pen.color = if ([curX, curY] == [col, row],
                    { Color.red; },
                    { Color.black; }
                );

                rect = Rect(col * gridSize, row * gridSize, gridSize, gridSize);
                Pen.addRect(rect);

                // Don't fill in rests
                if (outGrid[row][col][0] == 0,
                    { Pen.perform(\stroke); },
                    { Pen.perform(\fill); }
                );
            };
        };
    };

    // Initialize the inner displays
    // One display for each currently playing inner grid
    inDisplays = Array.fill(maxPlaying, nil);
    maxPlaying.do {|i|
        inDisplays[i] = Window(
            "Inner Grid" + (i + 1),
            Rect(100, (i + 1) * (inRows * gridSize + 50), inCols * gridSize, inRows * gridSize),
            false
        ).front;
        inDisplays[i].view.background = Color.white;

        // See below in the play routine for an explanation
        inDisplays[i].addUniqueMethod(\inGrid, { Array.fill2D(inRows, inCols, 0) });

        inDisplays[i].drawFunc = {|display|
            var rect;

            Pen.color = Color.black;

            inRows.do {|row|
                inCols.do {|col|
                    rect = Rect(col * gridSize, row * gridSize, gridSize, gridSize);
                    Pen.addRect(rect);

                    // Don't fill in 0 values
                    if (display.inGrid[row][col] == 0,
                        { Pen.perform(\stroke); },
                        { Pen.perform(\fill); }
                    );
                };
            };
        };
    };

    // The main loop
    play = Routine({
        var playingIdx;
        var newPeriod, newIdx, delay;

        delay = 1/4;

        // The playing array keeps track of the last maxPlaying inner grids
        // It stores the period and index of the grid, plus the event stream
        // so it can stop old values from playing
        playingIdx = 0;
        playing = Array.fill(maxPlaying, { [0, 0, Pbind(\degree, \rest).play]; });

        inf.do {|step|
            // Look at the current cell
            # newPeriod, newIdx = outGrid[curY][curX];

            // Do nothing on rests
            if (newPeriod != 0,
                {
                    // Replace the old inner grid
                    playing[playingIdx][0] = newPeriod;
                    playing[playingIdx][1] = newIdx;
                    playingIdx = (playingIdx + 1) % maxPlaying;
                }
            );

            // Update the playing inner grids
            maxPlaying.do {|i|
                var period, idx, pattern, inGrid;

                # period, idx = playing[i];

                if (period != 0,
                    {
                        // Get the inner grid and go the appropriate number of steps
                        // Each inner cell does one step every time the outer
                        // position moves
                        inGrid = innerGrids[period][idx];
                        inGrid = stepInner.value(inGrid, step % period);

                        // Handle the inner grid
                        pattern = playInner.value(inGrid);

                        // Stop the old pattern and start the new one
                        playing[i][2].stop;
                        playing[i][2] = pattern.play;
                    },
                    {
                        // Display an empty inner grid if period is 0
                        inGrid = Array.fill2D(inRows, inCols, 0);
                    }
                );

                // Update the inner display

                // addUniqueMethod is sort of a hack to pass some information (the inner
                // grid) to the draw method
                // defer is needed because TempoClock can't schedule GUI events, needs to
                // be AppClock
                {
                    inDisplays[i].addUniqueMethod(\inGrid, { inGrid; });
                    inDisplays[i].refresh;
                }.defer;
            };

            // Move the position randomly, loops to the other side if an edge is reached
            curX = (curX + (-1 .. 1).choose) % outCols;
            curY = (curY + (-1 .. 1).choose) % outRows;

            // Update the outer display
            { outDisplay.refresh; }.defer;

            // Wait to move to the next outer cell
            delay = getDelay.value(delay);
            delay.wait;
        };
    });

    // Start the song
    play.play;

    // Stop the song after duration seconds
    AppClock.sched(duration, {|time|
        play.stop;
        playing.do {|player|
            player[2].stop;
        };
        Window.closeAll;
        nil;
    });
};

/*** Examples ***/
var examples = {
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
    ~period = 3; //rrand(1,3);
    ~grid = innerGrids[~period].choose;
    ("Initial with period" + ~period).postln;
    ~grid.do {|row| row.join.postln; };

    ~period.do {|i|
        ("Step" + (i + 1)).postln;
        ~grid = stepInner.value(~grid);
        ~grid.do {|row| row.join.postln; };
    };
};

//examples.value();
playSong.value();
);

// Cleanup
(
Window.closeAll;
)