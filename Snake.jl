using Luxor
using MiniFB
using Colors

# --- Game Configuration ---
const GRID_SIZE = 20         # Size of each cell in pixels
const BOARD_WIDTH_CELLS = 30 # Board width in number of cells
const BOARD_HEIGHT_CELLS = 20 # Board height in number of cells

const WINDOW_WIDTH = GRID_SIZE * BOARD_WIDTH_CELLS
const WINDOW_HEIGHT = GRID_SIZE * BOARD_HEIGHT_CELLS
const FPS = 10               # Game speed (frames per second / ticks per second)

# Colors
const COLOR_BACKGROUND = Luxor.RGB(0.1, 0.1, 0.15)
const COLOR_SNAKE_HEAD = Luxor.RGB(0.2, 0.8, 0.2)
const COLOR_SNAKE_BODY = Luxor.RGB(0.1, 0.6, 0.1)
const COLOR_FOOD = Luxor.RGB(1.0, 0.3, 0.3) # Bright Red
const COLOR_TEXT = Luxor.RGB(0.9, 0.9, 0.9)
const COLOR_OVERLAY_TEXT = Luxor.RGB(1.0, 1.0, 1.0)
const COLOR_OVERLAY_BG = Luxor.RGBA(0.2, 0.2, 0.2, 0.7)


# --- Game State ---
mutable struct GameState
    snake_body::Vector{Point}   # List of points (pixels) for snake segments, head is last
    food_pos::Point             # Position of the food (pixels)
    direction::Point            # Current direction vector (e.g., Point(GRID_SIZE, 0))
    next_direction::Point       # Buffered next direction from input
    score::Int
    game_over::Bool
    paused::Bool
    keys_pressed::Set{MiniFB.mfb_key} # Set of currently held keys

    GameState() = new(
        [], Point(0,0), Point(GRID_SIZE, 0), Point(GRID_SIZE, 0),
        0, false, false, Set{MiniFB.mfb_key}()
    )
end

# --- Helper Functions ---

"Converts cell coordinates (0-indexed) to pixel coordinates (top-left of cell)"
cell_to_pixel(cell_x::Int, cell_y::Int) = Point(cell_x * GRID_SIZE, cell_y * GRID_SIZE)

"Generates food at a random empty cell"
function generate_food!(gs::GameState)
    while true
        food_cell_x = rand(0:BOARD_WIDTH_CELLS-1)
        food_cell_y = rand(0:BOARD_HEIGHT_CELLS-1)
        new_food_pos = cell_to_pixel(food_cell_x, food_cell_y)

        # Ensure food doesn't spawn on the snake
        if !(new_food_pos in gs.snake_body)
            gs.food_pos = new_food_pos
            break
        end
    end
end

"Initializes or resets the game state"
function initialize_game!(gs::GameState)
    # Start snake in the middle, moving right, length 2
    start_cell_x = fld(BOARD_WIDTH_CELLS, 2)
    start_cell_y = fld(BOARD_HEIGHT_CELLS, 2)
    
    gs.snake_body = [
        cell_to_pixel(start_cell_x - 1, start_cell_y), # Tail
        cell_to_pixel(start_cell_x, start_cell_y)      # Head
    ]
    gs.direction = Point(GRID_SIZE, 0) # Moving Right
    gs.next_direction = Point(GRID_SIZE, 0)
    gs.score = 0
    gs.game_over = false
    gs.paused = false
    empty!(gs.keys_pressed) # Clear any lingering key presses
    generate_food!(gs)
end

# --- Drawing Functions ---

"Draws a single grid cell as a filled box"
function draw_cell(pos::Point, color, border_reduction=2)
    # pos is top-left of cell, box is centered
    center_pos = pos + Point(GRID_SIZE/2, GRID_SIZE/2)
    sethue(color)
    box(center_pos, GRID_SIZE - border_reduction, GRID_SIZE - border_reduction, :fill)
end

"Draws the entire game scene"
function draw_game(gs::GameState, buffer::Vector{UInt32})
    Drawing(WINDOW_WIDTH, WINDOW_HEIGHT, :image)
    origin() # Set (0,0) to top-left

    # Background
    background(COLOR_BACKGROUND)

    # Draw Food
    draw_cell(gs.food_pos, COLOR_FOOD)

    # Draw Snake
    for (i, segment_pos) in enumerate(gs.snake_body)
        color = (i == length(gs.snake_body)) ? COLOR_SNAKE_HEAD : COLOR_SNAKE_BODY
        draw_cell(segment_pos, color)
    end

    # Draw Score
    sethue(COLOR_TEXT)
    fontsize(18) # Slightly smaller for less intrusion
    text("Score: $(gs.score)", Point(10, WINDOW_HEIGHT - 10), valign=:bottom, halign=:left)

    # Game Over / Paused Message
    if gs.game_over
        setblend(COLOR_OVERLAY_BG) # Semi-transparent background for text
        box(Point(WINDOW_WIDTH/2, WINDOW_HEIGHT/2), WINDOW_WIDTH * 0.8, WINDOW_HEIGHT * 0.4, :fill)
        sethue(COLOR_OVERLAY_TEXT)
        fontsize(40)
        text("GAME OVER", Point(WINDOW_WIDTH/2, WINDOW_HEIGHT/2 - 20), halign=:center, valign=:middle)
        fontsize(20)
        text("Press 'R' to Restart", Point(WINDOW_WIDTH/2, WINDOW_HEIGHT/2 + 30), halign=:center, valign=:middle)
    elseif gs.paused
        setblend(COLOR_OVERLAY_BG)
        box(Point(WINDOW_WIDTH/2, WINDOW_HEIGHT/2), WINDOW_WIDTH * 0.6, WINDOW_HEIGHT * 0.3, :fill)
        sethue(COLOR_OVERLAY_TEXT)
        fontsize(40)
        text("PAUSED", Point(WINDOW_WIDTH/2, WINDOW_HEIGHT/2), halign=:center, valign=:middle)
    end

    # Transfer Luxor drawing to MiniFB buffer
    luxor_matrix = Luxor.drawing_as_matrix()
    # The buffer is 1D, row-major. Luxor matrix is height x width.
    idx = 1
    for r in 1:WINDOW_HEIGHT
        for c in 1:WINDOW_WIDTH
            buffer[idx] = luxor_matrix[r, c].color # ARGB32's .color is UInt32
            idx += 1
        end
    end
    finish() # Finalize Luxor drawing
end

# --- Game Logic Update ---
function update_game!(gs::GameState)
    if gs.game_over || gs.paused
        return
    end

    # Apply buffered direction
    gs.direction = gs.next_direction

    current_head = gs.snake_body[end]
    new_head = current_head + gs.direction

    # Wall Collision
    if !(0 <= new_head.x < WINDOW_WIDTH && 0 <= new_head.y < WINDOW_HEIGHT)
        gs.game_over = true
        return
    end

    # Self Collision (check all but the last segment, which will be removed if no food)
    # Important: If snake is very short (e.g. length 2), it cannot collide with itself by moving forward.
    # A collision occurs if the new_head position is already occupied by any existing body segment.
    if new_head in gs.snake_body
        # A special case: if the snake is just turning back on itself but hasn't grown yet,
        # the new_head might be where the tail *was*. But the tail will move.
        # So, a true self-collision is if new_head hits any part of the body *that will remain*.
        # If snake eats food, the tail doesn't move, so any overlap is a collision.
        # If snake doesn't eat, tail moves. Collision if new_head hits any segment *other than the current tail*.
        # Simpler: if new_head is in body, it's game over.
        # (Consider a 180 degree turn of a 2-segment snake: head tries to move to tail's spot.
        # Tail will move away, so it's not a collision.
        # But if head tries to move to body[1] of a 3-segment snake, it's a collision.)
        # The `new_head in gs.snake_body` check is generally correct.
        gs.game_over = true
        return
    end

    # Add new head
    push!(gs.snake_body, new_head)

    # Food Consumption
    if new_head == gs.food_pos
        gs.score += 10
        generate_food!(gs)
    else
        popfirst!(gs.snake_body) # Remove tail if no food eaten
    end
end


# --- Input Handling ---
# Global reference for the game state, accessible by the callback
# For more complex apps, use mfb_set_user_data / mfb_get_user_data.
GAME_STATE_REF = Ref{GameState}()

function keyboard_callback(window::Ptr{Cvoid}, key::MiniFB.mfb_key, mod::MiniFB.mfb_key_mod, is_pressed::Bool)
    if !isassigned(GAME_STATE_REF) return end
    gs = GAME_STATE_REF[]

    # Handle single-press actions (Pause, Restart)
    if is_pressed
        if key == MiniFB.KB_KEY_P && !gs.game_over
            gs.paused = !gs.paused
        elseif key == MiniFB.KB_KEY_R && gs.game_over
            initialize_game!(gs)
        end
    end

    # Update the set of currently pressed keys for continuous actions (movement, escape)
    if is_pressed
        push!(gs.keys_pressed, key)
    else
        delete!(gs.keys_pressed, key)
    end
end

"Processes held-down keys for movement and quitting"
function process_continuous_input!(gs::GameState)
    if gs.paused || gs.game_over # No movement input if paused or game over
        return
    end

    # Prioritize last pressed key for smoother turning if multiple arrows held?
    # For simplicity, first match wins.
    # next_direction is buffered to prevent 180-degree turn into self in one frame.
    # current gs.direction is what the snake *is* moving.
    # gs.next_direction is what it *will* move next tick.
    # We must not set next_direction to be opposite of current_direction.
    
    # Horizontal movement
    if MiniFB.KB_KEY_LEFT in gs.keys_pressed && gs.direction != Point(GRID_SIZE, 0)
        gs.next_direction = Point(-GRID_SIZE, 0)
    elseif MiniFB.KB_KEY_RIGHT in gs.keys_pressed && gs.direction != Point(-GRID_SIZE, 0)
        gs.next_direction = Point(GRID_SIZE, 0)
    # Vertical movement (allow changing from horizontal to vertical)
    elseif MiniFB.KB_KEY_UP in gs.keys_pressed && gs.direction != Point(0, GRID_SIZE)
        gs.next_direction = Point(0, -GRID_SIZE)
    elseif MiniFB.KB_KEY_DOWN in gs.keys_pressed && gs.direction != Point(0, -GRID_SIZE)
        gs.next_direction = Point(0, GRID_SIZE)
    end
end


# --- Main Game Loop ---
function main()
    # MFB_BUFFER_FORMAT_ARGB tells MiniFB to expect ARGB pixel data
    window = mfb_open_ex("Julia Snake Classic", WINDOW_WIDTH, WINDOW_HEIGHT, MiniFB.WF_RESIZABLE)
    if window == C_NULL
        @error "Could not create MiniFB window."
        return
    end
    mfb_set_target_fps(window, UInt32(FPS))

    gs = GameState()
    GAME_STATE_REF[] = gs # Make gs accessible to the callback
    initialize_game!(gs)

    # Buffer for MiniFB (UInt32 per pixel, ARGB format)
    buffer = zeros(UInt32, WINDOW_WIDTH * WINDOW_HEIGHT)

    # Set up keyboard callback
    # Note: The exact signature for @cfunction must match what MiniFB expects.
    keyboard_cb_c = @cfunction(keyboard_callback, Cvoid, (Ptr{Cvoid}, MiniFB.mfb_key, MiniFB.mfb_key_mod, Bool))
    mfb_set_keyboard_callback(window, keyboard_cb_c)

    println("Starting Snake Game. Controls: Arrows, P (Pause), R (Restart when Game Over), ESC (Quit).")

    running = true
    while running && mfb_wait_sync(window) # mfb_wait_sync handles timing and polls events
        
        process_continuous_input!(gs) # Process movement from gs.keys_pressed
        update_game!(gs)
        draw_game(gs, buffer)

        # Update window and get status
        # MFB_BUFFER_FORMAT_ARGB implicitly used if not specified in mfb_update_ex,
        # but good to be aware it matches Luxor's ARGB32.
        state = mfb_update_ex(window, buffer, WINDOW_WIDTH, WINDOW_HEIGHT)

        if state != MiniFB.STATE_OK
            println("Window closed or error. Exiting.")
            running = false
        end

        # Check for ESC key to quit (processed from gs.keys_pressed)
        if MiniFB.KB_KEY_ESCAPE in gs.keys_pressed
            println("Escape key pressed. Exiting.")
            running = false
        end
    end

    mfb_close(window)
    println("Game Over. Final Score: $(gs.score)")
end

# Run the game
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end