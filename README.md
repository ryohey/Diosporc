# Diosporc

![screenshot](https://user-images.githubusercontent.com/5355966/44294839-6d964380-a2d8-11e8-86ff-5972fa4fcf72.png)

## Controls

- Click on the canvas: Create the memory block
- Click on the memory block: Increase the value
- Right click on the memory block: Decrease the value
- Right button drag from memory to function block: Create the link
- Middle click on the block: Remove the block
- Middle click on the link: Remove the link

## Blocks

### `+` `-` `*` `/`

Calculate input values.

### `=` `and` `or` `<` `>`

Compare input values and output binary. (0 = false, 1 = true)

### `if`

If the first input value is 0, it outputs the third input value, otherwise it outputs the second input value.

### `pointer`

Output the value of the block at the address pointed to by the input value.

### `alloc`

Generate a memory block by the number of input values and output the pointer of the first block.

### `stdout`

Output values to the console.

### `toChar`

Convert values to characters.

