using TurtleGraphics
using Dates

# Constants\const SEG_SIZE = 20
const INITIAL_LENGTH = 5
const MOVE_DELAY = Millisecond(150)

# Global state
mutable struct Vec2
    x::Int
    y::Int
end

# Initial snake as a vector of Vec2 segments
snake = [Vec2(-i*SEG_SIZE, 0) for i in 0:INITIAL_LENGTH-1]
# Movement direction: right by default
direction = Vec2(1, 0)

# Create screen and turtle
screen = Window(width=600, height=600, title="Julia Snake Game")
turtle = Turtle(screen)
penup(turtle)
hideturtle(turtle)
speed(turtle, 0)  # instant drawing

# Draw one square segment at pos
def draw_segment(pos::Vec2)
    setpos(turtle, (pos.x, pos.y))
    pendown(turtle)
    begin_fill(turtle)
    for _ in 1:4
        forward(turtle, SEG_SIZE)
        left(turtle, 90)
    end
    end_fill(turtle)
    penup(turtle)
end

# Render the entire snake
function draw_snake()
    clear(turtle)
    for seg in snake
        draw_segment(seg)
    end
    update(screen)
end

# Movement step: move head, shift body
function move_snake!()
    # compute new head
    head = snake[1]
    new_head = Vec2(head.x + direction.x*SEG_SIZE,
                    head.y + direction.y*SEG_SIZE)
    # insert and drop last
    unshift!(snake, new_head)
    pop!(snake)
end

# Key event handlers
function on_key(event)
    k = event[:key]
    if k == :Up && direction.y != -1
        direction.x, direction.y = 0, 1
    elseif k == :Down && direction.y != 1
        direction.x, direction.y = 0, -1
    elseif k == :Left && direction.x != 1
        direction.x, direction.y = -1, 0
    elseif k == :Right && direction.x != -1
        direction.x, direction.y = 1, 0
    end
end

# Bind arrow keys
each(event -> on_key(event), screen, KeyPress)
listen(screen)

# Main loop as @async timer
task = @async begin
    while isopen(screen)
        move_snake!()
        draw_snake()
        sleep(MOVE_DELAY.value/1000)
    end
end

# Block until window closes
wait(task)
