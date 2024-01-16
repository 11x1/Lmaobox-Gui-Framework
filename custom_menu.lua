local debug = {
    setup = true,
    tab = true,
    textures = true,

    dynamic_antiaim = false
}

local controls = { }
local gui, draw = gui, draw


local vector = { }
local vector_mt = { }

local function clamp( v, min, max )
    return math.max( min, math.min( v, max ) )
end

function vector_mt.__add( self, vec2 )
    if type( vec2 ) == "number" then
        return vector.new( self.x + vec2, self.y + vec2, self.z + vec2 )
    end

    return vector.new( self.x + vec2.x, self.y + vec2.y, self.z + vec2.z )
end

function vector_mt.__sub( self, vec2 )
    return vector_mt.__add( self, vec2 * -1 )
end

function vector_mt.__mul( self, vec2 )
    if type( vec2 ) == "number" then
        return vector.new( self.x * vec2, self.y * vec2, self.z * vec2 )
    end

    return vector.new( self.x * vec2.x, self.y * vec2.y, self.z * vec2.z )
end

function vector_mt.__div( self, vec2 )
    if type( vec2 ) == "number" then
        return vector.new( self.x / vec2, self.y / vec2, self.z / vec2 )
    end

    return vector.new( self.x / vec2.x, self.y / vec2.y, self.z / vec2.z )
end

function vector_mt.__unm( self )
    return self * -1
end

function vector_mt.__eq( self, vec2 )
    if type( vec2 ) ~= "table" then
        return false
    end

    return self.x == vec2.x and self.y == vec2.y and self.z == vec2.z
end

function vector_mt.__len( self )
    return math.sqrt( self.x ^ 2 + self.y ^ 2 + self.z ^ 2 )
end

function vector_mt.__tostring( self )
    return ( 'vector( %.2f, %.2f, %.2f )' ):format( self.x, self.y, self.z )
end

function vector_mt.unpack( self )
    return self.x, self.y, self.z
end

function vector.new( x, y, z )
    local vx, vy, vz = x, y, z

    if x == nil then
        vx, vy, vz = 0, 0, 0
    end

    if vy == nil then
        vy = x
        vz = x
    end

    if vz == nil then
        vz = 0
    end

    local new_vec = {
        x = vx,
        y = vy,
        z = vz,
        unpack = vector_mt.unpack
    }

    setmetatable( new_vec, vector_mt )

    return new_vec
end

setmetatable( vector, {
    __call = function( self, ... )
        return vector.new( ... )
    end
} )


local color = { }
local color_mt = { }

local function parse_hex_string( hex_string )
    if #hex_string == 6 then
        hex_string = hex_string .. 'FF'
    end

    hex_string = hex_string:gsub( '#', '' )

    local to_return = { }
    for i = 1, 8, 2 do
        table.insert(
            to_return,
            tonumber( ( '0x%s' ):format( hex_string:sub( i, i + 1 ) ) )
        )
    end

    return table.unpack( to_return )
end

function color_mt.unpack( self )
    return math.floor( self.r ), math.floor( self.g ), math.floor( self.b ), math.floor( self.a )
end

function color.new( r, g, b, a )
    if type( r ) == "string" then
        r, g, b, a = parse_hex_string( r )
    end

    if g == nil then
        g, b = r, r
        a = 255
    end

    if b == nil then
        a = g
        g, b = r, r
    end

    if a == nil then
        a = 255
    end

    local new_color = {
        r = r, g = g, b = b, a = a,
        unpack = color_mt.unpack
    }

    setmetatable( new_color, color_mt ) -- dont have an use for this atm, here for future usage

    return new_color
end

setmetatable( color, {
    __call = function( self, ... )
        return color.new( ... )
    end
} )

function color.hue_to_rgb( hue_degrees )
    local hue = hue_degrees / 360

    local r, g, b = 0, 0, 0

    if hue < 1 / 6 then
        r = 1
        g = hue * 6
    elseif hue < 2 / 6 then
        r = 1 - ( hue - 1 / 6 ) * 6
        g = 1
    elseif hue < 3 / 6 then
        g = 1
        b = ( hue - 2 / 6 ) * 6
    elseif hue < 4 / 6 then
        g = 1 - ( hue - 3 / 6 ) * 6
        b = 1
    elseif hue < 5 / 6 then
        r = ( hue - 4 / 6 ) * 6
        b = 1
    else
        r = 1
        b = 1 - ( hue - 5 / 6 ) * 6
    end

    return color( math.floor( r * 255 ), math.floor( g * 255 ), math.floor( b * 255 ) )
end

function color.hsb_to_rgb( h, s, b )
    local rgb = { r = 0, g = 0, b = 0 }

    if s == 0 then
        rgb.r = b * 255
        rgb.g = b * 255
        rgb.b = b * 255
    else
        local hue = ( h == 360 ) and 0 or h

        local sector = math.floor( hue / 60 )
        local sector_pos = ( hue / 60 ) - sector

        local p = b * ( 1 - s )
        local q = b * ( 1 - s * sector_pos )
        local t = b * ( 1 - s * ( 1 - sector_pos ) )

        if sector == 0 then
            rgb.r = b * 255
            rgb.g = t * 255
            rgb.b = p * 255
        elseif sector == 1 then
            rgb.r = q * 255
            rgb.g = b * 255
            rgb.b = p * 255
        elseif sector == 2 then
            rgb.r = p * 255
            rgb.g = b * 255
            rgb.b = t * 255
        elseif sector == 3 then
            rgb.r = p * 255
            rgb.g = q * 255
            rgb.b = b * 255
        elseif sector == 4 then
            rgb.r = t * 255
            rgb.g = p * 255
            rgb.b = b * 255
        elseif sector == 5 then
            rgb.r = b * 255
            rgb.g = p * 255
            rgb.b = q * 255
        end
    end

    return color(
        math.floor( rgb.r ),
        math.floor( rgb.g ),
        math.floor( rgb.b )
    )
end

function color.rgb_to_hsb( color_obj )
    local hue, saturation, brightness = 0, 0, 0

    local r = color_obj.r / 255
    local g = color_obj.g / 255
    local b = color_obj.b / 255

    local max = math.max( r, g, b )
    local min = math.min( r, g, b )

    brightness = max

    if max == 0 then
        saturation = 0
    else
        saturation = ( max - min ) / max
    end

    if max == min then
        hue = 0
    else
        local delta = max - min

        if max == r then
            hue = ( g - b ) / delta
        elseif max == g then
            hue = 2 + ( b - r ) / delta
        elseif max == b then
            hue = 4 + ( r - g ) / delta
        end

        hue = hue * 60

        if hue < 0 then
            hue = hue + 360
        end
    end

    return hue, saturation, brightness
end


local renderer = {
    fontflags = {
        [ 'i' ] = FONTFLAG_ITALIC, -- italic
        [ 'u' ] = FONTFLAG_UNDERLINE, -- underline
        [ 's' ] = FONTFLAG_STRIKEOUT, -- strikeout
        [ 'a' ] = FONTFLAG_ANTIALIAS, -- antialiasing
        [ 'b' ] = FONTFLAG_GAUSSIANBLUR, -- gaussianblur
        [ 'd' ] = FONTFLAG_DROPSHADOW, -- shadow
        [ 'o' ] = FONTFLAG_OUTLINE, -- outline
    }
}

function renderer.line( s, e, c )
    draw.Color( c:unpack( ) )
    draw.Line( s.x, s.y, e.x, e.y )
end

function renderer.line3d( s, e, c )
    local screen_pos1 = client.WorldToScreen( Vector3( s.x, s.y, s.z ) )
    local screen_pos2 = client.WorldToScreen( Vector3( e.x, e.y, e.z ) )

    if screen_pos1 and screen_pos2 then
        renderer.line(
            vector( screen_pos1[ 1 ], screen_pos1[ 2 ] ),
            vector( screen_pos2[ 1 ], screen_pos2[ 2 ] ),
            c
        )
    end
end

function renderer.rect( s, sz, c )
    draw.Color( c:unpack( ) )
    draw.OutlinedRect( s.x, s.y, s.x + sz.x, s.y + sz.y )
end

function renderer.rect_filled( s, sz, c )
    draw.Color( c:unpack( ) )
    draw.FilledRect( s.x, s.y, s.x + sz.x, s.y + sz.y )
end

function renderer.rect_fade_single_color( s, sz, c1, a1, a2, horiz )
    if horiz == nil then
        horiz = false
    end

    draw.Color( c1:unpack( ) )
    draw.FilledRectFade( s.x, s.y, s.x + sz.x, s.y + sz.y, a1, a2, horiz )
end

function renderer.rect_fade( s, sz, c1, c2, horiz )
    if horiz == nil then
        horiz = false
    end

    draw.Color( c1:unpack( ) )
    local a1 = c1.a
    draw.FilledRectFade( s.x, s.y, s.x + sz.x, s.y + sz.y, a1, 0, horiz )

    draw.Color( c2:unpack( ) )
    local a2 = c2.a
    draw.FilledRectFade( s.x, s.y, s.x + sz.x, s.y + sz.y, 10, a2, horiz )
end

function renderer.textured_rect( s, sz, texture )
    draw.Color(255, 255, 255, 255);
    draw.TexturedRect( texture, s.x, s.y, s.x + sz.x, s.y + sz.y )
end

function renderer.circle( s, r, c, p )
    if p == nil then
        p = 60
    end

    draw.Color( c:unpack( ) )
    draw.OutlinedCircle( s.x, s.y, r, p )
end

function renderer.circle_filled( s, r, c, p ) -- ! fix thx franz
    if p == nil then
        p = 60
    end

    draw.Color( c:unpack( ) )
    draw.OutlinedCircle( s.x, s.y, r, p )
end

function renderer.text( pos, col, text )
    draw.Color( col:unpack( ) )
    draw.Text( pos.x, pos.y, text )
end

function renderer.measure_text( text )
    return vector( draw.GetTextSize( text ) )
end

function renderer.create_font( fontname, sz_in_px, weight, flags_str )
    -- flags is expected to be a string
    -- i - italic
    -- u - underline
    -- s - strikeout
    -- a - antialiasing
    -- b - gaussianblur
    -- d - shadow
    -- o - outline

    local flags = flags_str == nil and FONTFLAG_CUSTOM | FONTFLAG_ANTIALIAS or flags_str == '' and FONTFLAG_NONE or FONTFLAG_CUSTOM

    if flags_str ~= nil then
        local letter = ''
        for i = 1, #flags_str do
            letter = string.sub( flags_str, i, i )

            if renderer.fontflags[ letter ] then
                flags = flags | renderer.fontflags[ letter ]
            end
        end
    end

    return draw.CreateFont( fontname, sz_in_px, weight, flags )
end

function renderer.use_font( font )
    draw.SetFont( font )
end


local lbox_localised_input = input
local input = { keys = { }, mouse_pos = vector( ) }
local function new_keypress_data( )
    return {
        last_state = false,
        pressed = false
    }
end

function input.is_key_down( key )
    return lbox_localised_input.IsButtonDown( key )
end

function input.get_mouse_pos( )
    return lbox_localised_input.GetMousePos( )
end

function input.get_poll_tick( )
    return lbox_localised_input.GetPollTick( )
end

function input.is_button_pressed( key )
    if not input.keys[ key ] then
        input.keys[ key ] = new_keypress_data( )
    end

    local keydata = input.keys[ key ]

    return keydata.pressed
end

local writable_keys = {
    [ '0' ]                = KEY_0,
    [ '1' ]                = KEY_1,
    [ '2' ]                = KEY_2,
    [ '3' ]                = KEY_3,
    [ '4' ]                = KEY_4,
    [ '5' ]                = KEY_5,
    [ '6' ]                = KEY_6,
    [ '7' ]                = KEY_7,
    [ '8' ]                = KEY_8,
    [ '9' ]                = KEY_9,
    [ 'A' ]                = KEY_A,
    [ 'B' ]                = KEY_B,
    [ 'C' ]                = KEY_C,
    [ 'D' ]                = KEY_D,
    [ 'E' ]                = KEY_E,
    [ 'F' ]                = KEY_F,
    [ 'G' ]                = KEY_G,
    [ 'H' ]                = KEY_H,
    [ 'I' ]                = KEY_I,
    [ 'J' ]                = KEY_J,
    [ 'K' ]                = KEY_K,
    [ 'L' ]                = KEY_L,
    [ 'M' ]                = KEY_M,
    [ 'N' ]                = KEY_N,
    [ 'O' ]                = KEY_O,
    [ 'P' ]                = KEY_P,
    [ 'Q' ]                = KEY_Q,
    [ 'R' ]                = KEY_R,
    [ 'S' ]                = KEY_S,
    [ 'T' ]                = KEY_T,
    [ 'U' ]                = KEY_U,
    [ 'V' ]                = KEY_V,
    [ 'W' ]                = KEY_W,
    [ 'X' ]                = KEY_X,
    [ 'Y' ]                = KEY_Y,
    [ 'Z' ]                = KEY_Z,
    [ '-' ]            = KEY_MINUS,
    [ '=' ]            = KEY_EQUAL,
    [ ' ' ]            = KEY_SPACE,
    [ 'ENTER' ]            = KEY_ENTER,
    [ 'BACKSPACE' ]        = KEY_BACKSPACE,
}
function input.get_writable_key( )
    local is_upper = input.is_key_down( KEY_LSHIFT ) or input.is_key_down( KEY_RSHIFT )

    for k, v in pairs( writable_keys ) do
        if input.is_button_pressed( v ) then
            return is_upper and k:upper( ) or k:lower( )
        end
    end
end

function input.update_keys( )
    local mouse = input.get_mouse_pos( )
    local x, y = table.unpack( mouse )
    input.mouse_pos.x, input.mouse_pos.y = x, y

    for key in pairs( input.keys ) do
        local keydata = input.keys[ key ]
        local is_key_down = input.is_key_down( key )

        if is_key_down and not keydata.last_state then
            keydata.pressed = true
        else
            keydata.pressed = false
        end

        keydata.last_state = is_key_down
    end
end

local function is_in_bounds( pos, sz, pos_to_find_in )
    local x, y = input.mouse_pos:unpack( )

    if pos_to_find_in then
        x, y = pos_to_find_in.x, pos_to_find_in.y
    end

    return x >= pos.x and y >= pos.y and x <= pos.x + sz.x and y <= pos.y + sz.y
end

local function get_intersect( pos, size )
    local slope_start = size.y / size.x
    local slope_end = -slope_start

    local center = pos + size / 2

    local mouse_relative = input.mouse_pos - center
    local x, y = 0, 0

    if mouse_relative.x == 0 then
        x = math.floor( pos.x + size.x / 2 )

        if mouse_relative.y > 0 then
            y = pos.y + size.y
        else
            y = pos.y
        end
    else
        local mouse_slope = -mouse_relative.y / mouse_relative.x

        if mouse_slope < slope_start and mouse_slope > slope_end then
            -- sides
            x = mouse_relative.x > 0 and pos.x + size.x or pos.x
            y = math.floor( pos.y + size.y / 2 + ( size.x * mouse_slope * ( mouse_relative.x > 0 and -1 or 1 ) ) / 2 )
        else
            -- sides
            y = mouse_relative.y > 0 and pos.y + size.y or pos.y
            x = math.floor( pos.x + size.x / 2 + ( size.y / mouse_slope * ( mouse_relative.y > 0 and -1 or 1 ) ) / 2 )
        end
    end

    return vector( x, y )
end

local left_directions = {
    vector( -1,  0 ),
    vector(  0,  1 ),
    vector(  1,  0 ),
    vector(  0, -1 )
}

local function wrap_index( tbl, idx )
    idx = idx % #tbl + 1

    return tbl[ idx ]
end

local function bind( fn, ... )
    local args = { ... }
    return function( )
        fn( table.unpack( args ) )
    end
end

local max_iterations = 3
local function render_wrapping_gradient( rect_pos, rect_size, gradient_start, max_length, width, side, col )
    local start_direction = 0
    local is_left = side == 'left'
    local index_direction = is_left and 1 or -1

    --* default to top
    local first_step_length = is_left and gradient_start.x - rect_pos.x or rect_pos.x + rect_size.x - gradient_start.x

    if gradient_start.x == rect_pos.x then
        --* left
        start_direction = 1
        first_step_length = is_left and rect_pos.y + rect_size.y - gradient_start.y or gradient_start.y - rect_pos.y
    elseif gradient_start.y == rect_pos.y + rect_size.y then
        --* bottom
        start_direction = 2
        first_step_length = is_left and rect_pos.x + rect_size.x - gradient_start.x or gradient_start.x - rect_pos.x
    elseif gradient_start.x == rect_pos.x + rect_size.x then
        --* right
        start_direction = 3
        first_step_length = is_left and gradient_start.y - rect_pos.y or rect_pos.y + rect_size.y - gradient_start.y
    end

    local gradient_segments = { }

    if first_step_length > max_length then
        table.insert(
            gradient_segments,
            max_length
        )
    else
        table.insert(
            gradient_segments,
            first_step_length
        )

        local remaining_length = max_length - first_step_length

        local use_height = start_direction % 2 == 0

        local iteration = 1
        while remaining_length > 0 do
            if iteration > max_iterations then
                break
            end

            local max = use_height and rect_size.y or rect_size.x

            local can_do_partly = remaining_length < max

            if can_do_partly then
                table.insert(
                    gradient_segments,
                    remaining_length
                )
                break
            end

            --* ok we can do normally, add max and deduct from remaining
            table.insert(
                gradient_segments,
                max + width
            )

            remaining_length = remaining_length - max
            
            use_height = not use_height
            iteration = iteration + 1
        end
    end

    --* calculate section alphas
    local gradient_alphas = { }
    for i = 1, #gradient_segments do
        local length = gradient_segments[ i ]
        local perc = length / max_length
        
        local alpha_taken = math.floor( perc * col.a )

        table.insert(
            gradient_alphas,
            alpha_taken
        )
    end

    --* gradient_segments table now contains each segments length
    --* next up is the logic to draw the segments

    local render_start_pos = gradient_start

    local alpha = col.a
    for i = 1, #gradient_segments do
        local direction = wrap_index( left_directions, start_direction )
        direction = direction * index_direction

        local gradient_length = gradient_segments[ i ]
        local alpha_taken = gradient_alphas[ i ]

        local alpha_start = alpha
        local alpha_end = alpha_start - alpha_taken

        if direction.x == 1 then
            local start_pos = is_left and render_start_pos or render_start_pos - vector( 0, width )
            local size = vector( gradient_length, width )
            renderer.rect_fade_single_color(
                start_pos, size, col,
                alpha_start, alpha_end, true
            )
        elseif direction.x == -1 then
            local start_pos = is_left and render_start_pos or render_start_pos - vector( 0, width )
            local size = vector( gradient_length, width )
            start_pos = start_pos - vector( gradient_length, is_left and width or -width )

            renderer.rect_fade_single_color(
                start_pos, size, col,
                alpha_end, alpha_start, true
            )
        elseif direction.y == 1 then
            local start_pos = is_left and render_start_pos - vector( width, 0 ) or render_start_pos
            local size = vector( width, gradient_length )

            renderer.rect_fade_single_color(
                start_pos, size, col,
                alpha_start, alpha_end, false
            )
        elseif direction.y == -1 then
            local start_pos = is_left and render_start_pos or render_start_pos - vector( width, 0 )
            local size = vector( width, gradient_length )
            start_pos = start_pos - vector( 0, gradient_length )

            renderer.rect_fade_single_color(
                start_pos, size, col,
                alpha_end, alpha_start, false
            )
        end
        
        start_direction = start_direction + index_direction

        local next_direction = wrap_index( left_directions, start_direction )
        next_direction = next_direction * index_direction

        if next_direction.x == 1 then
            render_start_pos = is_left and rect_pos + vector( -width, rect_size.y ) or rect_pos + vector( -width, 0 )
        elseif next_direction.x == -1 then
            render_start_pos = is_left and rect_pos + vector( rect_size.x + width, 0 ) or rect_pos + rect_size + vector( width, 0 )
        elseif next_direction.y == 1 then
            render_start_pos = is_left and rect_pos + vector( 0, -width ) or rect_pos + vector( rect_size.x, -width )
        elseif next_direction.y == -1 then
            render_start_pos = is_left and rect_pos + rect_size + vector( 0, width ) or rect_pos + vector( 0, rect_size.y + width )
        end

        alpha = alpha - alpha_taken
    end

end

local id_indexer = 0
local function generate_id( )
    id_indexer = id_indexer + 1
    return id_indexer
end

local function time_to_ticks( t )
    return math.floor( 0.5 + (t / globals.TickInterval( ) ) )
end

local function ticks_to_time( t )
    return globals.TickInterval( ) * t
end

function table.has_value( t, val )
    for k, v in pairs( t ) do
        if v == val then
            return true
        end
    end

    return false
end

function table.has_key( t, key )
    for k, _ in pairs( t ) do
        if k == key then return true end
    end

    return false
end

local function new_orderer_table( )
    local tbl = { }

    tbl.kv_tbl = { }
    tbl.key_order = { }
    tbl.value_order = { }

    function tbl:add( key, value )
        self.kv_tbl[ key ] = value
        table.insert(
            self.key_order,
            key
        )
        table.insert(
            self.value_order,
            value
        )
    end

    function tbl:has( key )
        local has, idx = false, nil
        for i = 1, #self.key_order do
            if self.key_order[ i ] == key then
                has = true
                break
            end
        end

        return has, idx
    end

    function tbl:update( key, value )
        local has_key, key_idx = self:has( key )

        if has_key then
            self.value_order[ key_idx ] = value
            self.kv_tbl[ key ] = value
        else
            self:add( key, value )
        end

        return self.kv_tbl[ key ]
    end

    function tbl:get_keys( )
        return self.key_order
    end

    function tbl:get_values( )
        return self.value_order
    end

    setmetatable( tbl, {
        __newindex = function ( self, k, v )
            return self:update( k, v )
        end,

        __index = function( self, k )
            return self.kv_tbl[ k ]
        end
    })

    return tbl
end

local accent_color = color( '6feaa7' )
local accent_color_light = color( accent_color.r * 1.1, accent_color.g, accent_color.b * 1.1 )

local subtab_font = renderer.create_font( 'Verdana', 20, 100 )
local group_title_font = renderer.create_font( 'Verdana', 16, 600 )
local controls_font = renderer.create_font( 'Verdana', 16, 100 )

local font_height = { }
renderer.use_font( subtab_font )
font_height.subtab = renderer.measure_text( 'ABC' ).y
renderer.use_font( group_title_font )
font_height.group_title = renderer.measure_text( 'ABC' ).y
renderer.use_font( controls_font )
font_height.controls = renderer.measure_text( 'ABC' ).y

local global_colors = {
    disabled_text = color( 'adadad' ),
    hint_text = color( '7d7d7d' ),
    checkbox = color( '414141' ),
    hovered_text = color( 210 ),
    highlight_hover = color( 200, 120 ),
    black = color( 0 ),
}

local function create_texture( active_img_tbl, inactive_img, width, height, debug_name )
    -- active_img_tbl consists of raw data in rgba8888 format, layered from bottom to up (lowest->highest index)
    -- last layer will be drawn with the accent color
    local texture = { }
    
    texture.active_textures = { }
    texture.inactive_texture = draw.CreateTextureRGBA( inactive_img, width, height )
    texture.size = vector( width, height )

    for active_data_idx = 1, #active_img_tbl do
        table.insert(
            texture.active_textures,
            draw.CreateTextureRGBA( active_img_tbl[ active_data_idx ], width, height )
        )
    end

    if debug.textures then
        print( ( '[txtrs]\tcreated "%s" %i active textures + 1 inactive texture (all %ix%i).' ):format( debug_name, #active_img_tbl, width, height ) )

        for i = 1, #texture.active_textures do
            print( ( '\t↳ created active texture id: %i' ):format( texture.active_textures[ i ] ) )
        end

        print( ( '\t↳ created inactive texture id: %i' ):format( texture.inactive_texture ) )
    end

    function texture:render( pos, sz, active )
        draw.Color( 255, 255, 255, 255 )

        if active then
            for i = 1, #self.active_textures do
                if i == #self.active_textures then
                    draw.Color( math.floor( accent_color_light.r ), math.floor( accent_color_light.g ), math.floor( accent_color_light.b ), math.floor( accent_color_light.a ) )
                end
                draw.TexturedRect( self.active_textures[ i ], pos.x, pos.y, pos.x + sz.x, pos.y + sz.y )
            end
        else
            draw.TexturedRect( self.inactive_texture, pos.x, pos.y, pos.x + sz.x, pos.y + sz.y )
        end
    end

    function texture:destroy( )
        for i = 1, #self.active_textures do
            print( '\tdeleting texture id (active): ' .. tostring( self.active_textures[ i ] ) )
            draw.DeleteTexture( self.active_textures[ i ] )
        end

        print( '\tdeleting texture id (inactive): ' .. tostring( self.inactive_texture ) )
        draw.DeleteTexture( self.inactive_texture )

        if debug.textures then
            print( ( '\t↳ deleted %i textures.' ):format( #self.active_textures + 1 ) )
        end
    end

    return texture
end

local success, abs_data_folder_path = filesystem.CreateDirectory( 'cool gui' )

if not success and not abs_data_folder_path then
    error( '[fatal error] couldn\'t create images folder.' )
end

local function get_file_data( file_path )
    local file = io.open(
        file_path,
        'r'
    )

    io.input( file )

    return io.read( )
end

local texture_paths = {
    rage = {
        low_level = ( '%s\\rage_active_bg.raw' ):format( abs_data_folder_path ),
        upper_layer = ( '%s\\rage_active_border.raw' ):format( abs_data_folder_path ),
        inactive = ( '%s\\rage_inactive.raw' ):format( abs_data_folder_path ),
    },
    legit = {
        low_level = ( '%s\\legit_active_bg.raw' ):format( abs_data_folder_path ),
        upper_layer = ( '%s\\legit_active_border.raw' ):format( abs_data_folder_path ),
        inactive = ( '%s\\legit_inactive.raw' ):format( abs_data_folder_path ),
    },
    antiaim = {
        low_level = ( '%s\\antiaim_active_bg.raw' ):format( abs_data_folder_path ),
        upper_layer = ( '%s\\antiaim_active_outline.raw' ):format( abs_data_folder_path ),
        inactive = ( '%s\\antiaim_inactive.raw' ):format( abs_data_folder_path ),
    },
    esp = {
        low_level = ( '%s\\esp_active_bg.raw' ):format( abs_data_folder_path ),
        upper_layer = ( '%s\\esp_active_outline.raw' ):format( abs_data_folder_path ),
        inactive = ( '%s\\esp_inactive.raw' ):format( abs_data_folder_path ),
    },
    misc = {
        low_level = ( '%s\\misc_active_outline.raw' ):format( abs_data_folder_path ),
        inactive = ( '%s\\misc_inactive.raw' ):format( abs_data_folder_path ),
    },

    move = {
        main = ( '%s\\move_active.raw' ):format( abs_data_folder_path ),
        inactive = ( '%s\\move_inactive.raw' ):format( abs_data_folder_path ),
    }
}

local texture_data = { }

for tab_name, tab_icon_paths in pairs( texture_paths ) do
    texture_data[ tab_name ] = { }

    for idx_value, path in pairs( tab_icon_paths ) do
        texture_data[ tab_name ][ idx_value ] = get_file_data( path )
    end
end

local menu_tab_icons = {
    rage = create_texture( { texture_data.rage.low_level, texture_data.rage.upper_layer }, texture_data.rage.inactive, 128, 128, 'rage' ),
    legit = create_texture( { texture_data.legit.low_level, texture_data.legit.upper_layer }, texture_data.legit.inactive, 128, 128, 'legit' ),
    antiaim = create_texture( { texture_data.antiaim.low_level, texture_data.antiaim.upper_layer }, texture_data.antiaim.inactive, 128, 128, 'antiaim' ),
    esp = create_texture( { texture_data.esp.low_level, texture_data.esp.upper_layer }, texture_data.esp.inactive, 128, 128, 'esp' ),
    misc = create_texture( { texture_data.misc.low_level, texture_data.misc.upper_layer }, texture_data.misc.inactive, 128, 128, 'misc' ),

    move = create_texture( { texture_data.move.main }, texture_data.move.inactive, 128, 128, 'move' )
}

local zero_opacity_bg = ( function( )
    local texture = {
        0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
        1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
        0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
        1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
    
    }
    
    local colors = {
        '\xDD\xDD\xDD\xFF',
        '\x88\x88\x88\xFF'
    }
    
    local texture_data = { }
    
    for i = 1, #texture do
        local val = texture[ i ]
    
        table.insert( texture_data, colors[ val + 1 ] )
    end
    
    local color_data = table.concat( texture_data, '' )
    local texture_obj = draw.CreateTextureRGBA( color_data, 16, 4 )

    return texture_obj
end )( )

local function render_color_head( pos, size )
    renderer.rect_filled(
        pos,
        size,
        color( 255 )
    )

    renderer.rect(
        pos,
        size,
        color( 0 )
    )
end

function controls.new_colorpicker( control, gui_link_str, default_color )
    local picker = { }
    picker.topmost = true

    picker.color = default_color == nil and global_colors.highlight_hover or default_color
    picker.open = false

    picker.parent = control

    picker.changing = {
        big = false,
        hue = false,
        opacity = false
    }

    picker.visible = true

    -- the return value is random and doesnt follow a strict pattern
    picker.gui = gui_link_str

    -- if picker.gui then
    --     picker.color = gui.GetValue( gui_link_str )
    --     local hex_str = string.format("%x", picker.color )
    --     local color_str = string.sub( hex_str, #hex_str - 7, #hex_str - 2 )

    --     print( 'color str: ', color_str, 'hex str: ', hex_str )
    -- end

    local h, s, b = color.rgb_to_hsb( picker.color )

    picker.values = {
        big = vector( s, 1 - b ),
        hue = h / 360,
        opacity = picker.color.a
    }

    picker.areas = {
        hue = h,
        saturation = s,
        brightness = b,
    }

    picker.size = {
        menu = vector( 30, font_height.controls - 2 )
    }

    picker.picker = {
        gap = vector( 4 ),
        big = vector( 80, 80 ),
        hue = vector( 16, 80 ),
        opacity = vector( 80 + 16 + 4, 16 )
    }

    picker.picker.total = picker.picker.big + vector( picker.picker.hue.x, picker.picker.opacity.y ) + picker.picker.gap * 3 -- left right middle, top middle bottom

    picker.hovering = false

    picker.callback_fn = nil

    function picker:get( )
        return color( color_mt.unpack( self.color ) )
    end

    function picker:set( col )
        local h, s, b = color.rgb_to_hsb( col )

        self.values = {
            big = vector( s, 1 - b ),
            hue = h / 360,
            opacity = picker.color.a
        }
    
        self.areas = {
            hue = h,
            saturation = s,
            brightness = b,
        }

        self.color = col
    end

    function picker:set_callback( fn )
        self.callback_fn = fn
    end

    function picker:do_allow_further_handling( )
        return not self.open
    end

    function picker:is_hovering( )
        return self.hovering
    end

    function picker:handle( )
        local is_m1_pressed = input.is_button_pressed( MOUSE_LEFT )

        if is_m1_pressed and self.hovering then
            self.open = not self.open
        elseif is_m1_pressed and not self.hovering and not self.in_colorpicker then
            self.open = false
        end
    end

    function picker:handle_dropdown( pos, width )
        local render_pos = pos + vector( width, 0)

        local picker_size = self.picker.total
        local picker_start = render_pos

        local is_m1_pressed = input.is_button_pressed( MOUSE_LEFT )

        self.in_colorpicker = is_in_bounds( picker_start, picker_size )

        local is_m1_down = input.is_key_down( MOUSE_LEFT )

        local color_box_start = picker_start + self.picker.gap
        local color_box_size = self.picker.big
        local in_big_bounds = is_in_bounds( color_box_start, color_box_size )

        local hue_start = color_box_start + vector( color_box_size.x + self.picker.gap.x, 0  )
        local hue_size = self.picker.hue
        local in_hue_bounds = is_in_bounds( hue_start, hue_size )

        local opacity_start = color_box_start + vector( 0, color_box_size.y + self.picker.gap.y )
        local opacity_size = self.picker.opacity
        local in_opacity_bounds = is_in_bounds( opacity_start, opacity_size )

        if not self.in_colorpicker and is_m1_pressed and not self.hovering then
            self.open = false
            self.changing.big = false
            self.changing.hue = false
            self.changing.opacity = false
        end

        if is_m1_down then
            if in_big_bounds and not self.changing.hue and not self.changing.opacity then
                self.changing.big = true
                self.changing.hue = false
                self.changing.opacity = false
            elseif in_hue_bounds and not self.changing.big and not self.changing.opacity then
                self.changing.big = false
                self.changing.hue = true
                self.changing.opacity = false
            elseif in_opacity_bounds and not self.changing.big and not self.changing.hue then
                self.changing.big = false
                self.changing.hue = false
                self.changing.opacity = true
            end
        else
            self.changing.big = false
            self.changing.hue = false
            self.changing.opacity = false
        end

        local mouse = input.get_mouse_pos( )
        local x, y = table.unpack( mouse )
        local mouse_pos = vector( x, y )
    
        if self.changing.big then
            local diff = mouse_pos - color_box_start
            local diff_pc = diff / color_box_size

            diff_pc.x = clamp( diff_pc.x, 0, 1 )
            diff_pc.y = clamp( diff_pc.y, 0, 1 )

            self.values.big = diff_pc
        elseif self.changing.hue then
            local y_diff = mouse_pos.y - hue_start.y
            local y_diff_pc = clamp( y_diff / hue_size.y, 0, 1 )

            self.values.hue = y_diff_pc
        elseif self.changing.opacity then
            local x_diff = mouse_pos.x - opacity_start.x
            local x_diff_pc = clamp( x_diff / opacity_size.x, 0, 1 )

            self.values.opacity = x_diff_pc
        end


        self.areas.hue = math.floor( self.values.hue * 360 + 0.5 )
        self.areas.saturation = self.values.big.x
        self.areas.brightness = 1 - self.values.big.y

        local rgb_color = color.hsb_to_rgb( self.areas.hue, self.areas.saturation, self.areas.brightness )
        rgb_color.a = clamp( math.floor( self.values.opacity * 255 + 0.5 ), 0, 255 )

        self.color = rgb_color

        if self.gui then
            local numerical = self.color.r * 256^3 + self.color.g * 256^2 + self.color.b * 256 + self.color.a
            gui.SetValue( self.gui, numerical )
        end

        if self.callback_fn ~= nil then
            self.callback_fn( self )
        end
    end


    function picker:render_dropdown( pos, width )
        picker:handle_dropdown( pos, width )

        local render_pos = pos + vector( width, 0)

        local picker_size = self.picker.total
        local picker_start = render_pos

        renderer.rect_filled(
            picker_start,
            picker_size,
            color( 40 )
        )

        renderer.rect(
            picker_start,
            picker_size,
            color( 0 )
        )

        -- render color box
        -- white to black vertical
        local color_box_start = picker_start + self.picker.gap
        local color_box_size = self.picker.big

        -- erm what the frick, no clue how but this seems to give the closest and best representation of a color picker (the main part)
        renderer.rect_fade_single_color(
            color_box_start,
            color_box_size,
            color( 255, 255, 255 ), 255, 0,
            false
        )

        local hue_to_rgb = color.hue_to_rgb( self.areas.hue )

        renderer.rect_fade_single_color(
            color_box_start,
            color_box_size,
            hue_to_rgb, 0, 255,
            true
        )
        
        renderer.rect_fade_single_color(
            color_box_start,
            color_box_size,
            color( 0, 0, 0 ), 0, 255,
            false
        )

        renderer.rect_fade_single_color(
            color_box_start,
            color_box_size,
            color( 0, 0, 0 ), 0, 255,
            false
        )

        -- render big one head
        local head_pos = color_box_start + color_box_size * self.values.big
        head_pos.x = math.floor( head_pos.x )
        head_pos.y = math.floor( head_pos.y )

        renderer.circle(
            head_pos,
            2,
            color( 0 ),
            4
        )

        renderer.circle(
            head_pos,
            1,
            color( 255 ),
            4
        )

        -- render hue oh god
        local hue_start = color_box_start + vector( color_box_size.x + self.picker.gap.x, 0  )
        local hue_size = self.picker.hue

        for i = 0, 300, 60 do
            local color_1 = color.hue_to_rgb( i )
            local color_2 = color.hue_to_rgb( i + 60 )

            renderer.rect_fade_single_color(
                hue_start + vector( 0, math.floor( i / 360 * hue_size.y + 0.5 ) ),
                vector( hue_size.x, math.floor( hue_size.y / 6 + ( i == 300 and 1 or 5 ) - 4 ) ),
                color_1,
                255,
                100, false
            )

            renderer.rect_fade_single_color(
                hue_start + vector( 0, math.floor( i / 360 * hue_size.y + 0.5 ) + 2 ),
                vector( hue_size.x, math.floor( hue_size.y / 6 + ( i == 300 and 1 or 5 ) - 4 ) ),
                color_2,
                0,
                255, false
            )
        end

        -- render hue slider head
        local slider_offset = vector( 2, 2 )
        local hue_slider_size = vector( hue_size.x, 0 ) + slider_offset * 2
        local hue_slider_pos = hue_start + vector( -slider_offset.x, math.floor( hue_size.y * self.values.hue ) - slider_offset.y )

        render_color_head( hue_slider_pos, hue_slider_size )

        -- render opacity
        local opacity_start = color_box_start + vector( 0, color_box_size.y + self.picker.gap.y )
        local opacity_size = self.picker.opacity

        renderer.textured_rect(
            opacity_start,
            opacity_size,
            zero_opacity_bg
        )

        renderer.rect_fade_single_color(
            opacity_start,
            opacity_size,
            color( 255 ), 0, 255, true
        )

        -- render opacity head
        local opacity_slider_size = vector( hue_slider_size.y, hue_slider_size.x )
        local opacity_slider_pos = opacity_start + vector( math.floor( opacity_size.x * self.values.opacity ) - slider_offset.x, -slider_offset.y )

        render_color_head( opacity_slider_pos, opacity_slider_size )
    end

    function picker:render( pos, width, should_handle )
        local render_pos = pos + vector( width - math.floor( self.parent.subtab.tab.menu.padding.group.x / 2 ) - self.size.menu.x, 0)

        renderer.rect_filled(
            render_pos,
            self.size.menu,
            self.color
        )

        renderer.rect(
            render_pos,
            self.size.menu,
            global_colors.black
        )

        if should_handle then
            self.hovering = is_in_bounds( render_pos, self.size.menu )

            self:handle( )
        end
    end

    return picker
end

function controls.new_checkbox( subtab, group, name, default_state, gui_link_str )
    local checkbox = { }

    checkbox.group = group
    checkbox.name = name

    checkbox.state = default_state
    checkbox.gui = gui_link_str
    checkbox.callback_fn = nil

    checkbox.visible = true

    checkbox.box_size = vector( font_height.controls )
    checkbox.box_check_pad = vector( 3 )
    checkbox.check_size = checkbox.box_size - checkbox.box_check_pad * 2

    checkbox.subtab = subtab

    checkbox.visuals = {
        hovering = false
    }

    checkbox.colorpickers = { }
    checkbox.active_colorpicker = false

    if checkbox.gui then
        checkbox.state = gui.GetValue( gui_link_str ) == 1
    end

    function checkbox:get( )
        return self.state
    end

    function checkbox:set( new_state )
        self.state = new_state

        if self.callback_fn then
            self.callback_fn( self )
        end
    end

    function checkbox:add_color_picker( gui_link, default_color  )
        local picker = controls.new_colorpicker( self, gui_link, default_color )

        table.insert(
            self.colorpickers,
            picker
        )

        return picker
    end

    function checkbox:get_height( )
        return font_height.controls + 5
    end

    function checkbox:add_callback( fn )
        self.callback_fn = fn
    end

    function checkbox:set_visible( new_state )
        self.visible = new_state
    end

    function checkbox:click( )
        self.state = not self.state

        if self.gui then
            gui.SetValue( gui_link_str, self.state and 1 or 0 )
        end

        if self.callback_fn ~= nil then
            self.callback_fn( self )
        end
    end

    function checkbox:do_allow_further_handling( )
        return false
    end

    function checkbox:handle( pos, width )
        local in_bounds = is_in_bounds( pos, vector( width, self.box_size.y ) )
        local m1_click = input.is_button_pressed( MOUSE_LEFT )

        checkbox.visuals.hovering = in_bounds

        if in_bounds and m1_click then
            self:click( )
        end
    end

    function checkbox:render( pos, width, should_handle )
        if pos.y >= self.subtab.tab.menu.pos.y then
            local checkbox_start = pos + vector( self.subtab.tab.menu.padding.group.x / 2, 0)
            renderer.rect_filled(
                pos + vector( self.subtab.tab.menu.padding.group.x / 2, 0),
                self.box_size,
                global_colors.checkbox
            )

            if self.state then
                renderer.rect_filled(
                    checkbox_start + self.box_check_pad,
                    self.check_size,
                    accent_color
                )
            end

            -- render checkbox name
            local text_pos = checkbox_start + vector( self.box_size.x + self.subtab.tab.menu.padding.group.x / 2, self.box_size.y - font_height.controls - 1 )
            renderer.use_font( controls_font )
            renderer.text(
                text_pos,
                self.state and accent_color_light or self.visuals.hovering and global_colors.hovered_text or global_colors.disabled_text,
                self.name
            )

            -- render colorpickers
            local hovered_picker = nil
            self.active_colorpicker = nil
            for i = 1, #self.colorpickers do
                local picker = self.colorpickers[ i ]

                local x_offset = ( i - 1 ) * ( picker.size.menu.x + 5 )

                picker:render( pos, width - x_offset, should_handle )

                if not hovered_picker and picker:is_hovering( ) then
                    hovered_picker = picker
                elseif picker.open then
                    self.active_colorpicker = picker
                end
            end

        if hovered_picker and hovered_picker.open then
                self.active_colorpicker = hovered_picker
        end

            if should_handle and not self.active_colorpicker and not hovered_picker then
                self:handle( pos, width )
            end
        end
    end

    return checkbox
end

function controls.new_button( subtab, group, name )
    local button = { }

    button.group = group
    button.name = name

    renderer.use_font( controls_font )
    button.name_size = renderer.measure_text( name )

    button.callback_fn = nil

    button.visible = true

    button.box_size = vector( math.floor( font_height.controls * 1.5 ) )

    button.subtab = subtab

    button.visuals = {
        hovering = false,
        pressing = false
    }

    function button:get( )
        return true
    end

    function button:set( )
        
    end

    function button:get_height( )
        return self.box_size.y + 5
    end

    function button:add_callback( fn )
        self.callback_fn = fn
    end

    function button:set_visible( new_state )
        self.visible = new_state
    end

    function button:click( )
        if self.callback_fn ~= nil then
            self.callback_fn( self )
        end
    end

    function button:handle( pos, width )
        local in_bounds = is_in_bounds( pos, vector( width, self.box_size.y ) )
        local m1_click = input.is_button_pressed( MOUSE_LEFT )
        local m1_down = input.is_key_down( MOUSE_LEFT )

        self.visuals.hovering = in_bounds

        if in_bounds and m1_click then
            self:click( )
        end

        self.visuals.pressing = in_bounds and m1_down
    end

    function button:render( pos, width, should_handle )
        self.box_size.x = width - self.subtab.tab.menu.padding.group.x

        if pos.y >= self.subtab.tab.menu.pos.y then
            local button_start = pos + vector( math.floor( self.subtab.tab.menu.padding.group.x / 2 ), 0)
            renderer.rect_filled(
                button_start,
                self.box_size,
                self.visuals.pressing and global_colors.black or global_colors.checkbox
            )

            renderer.rect(
                button_start,
                self.box_size,
                global_colors.black
            )

            -- render button name
            local text_pos = button_start + vector( math.floor( self.box_size.x / 2 - self.name_size.x / 2 ), math.floor( self.box_size.y / 2 - self.name_size.y / 2 ) )
            renderer.use_font( controls_font )
            renderer.text(
                text_pos,
                self.visuals.hovering and global_colors.hovered_text or global_colors.disabled_text,
                self.name
            )

            if should_handle then
                self:handle( pos, width )
            end
        end
    end

    return button
end

function controls.new_text( subtab, group, name )
    local title = { }

    title.group = group
    title.name = name

    title.visible = true

    title.subtab = subtab

    title.visuals = {
        hovering = false
    }

    title.colorpickers = { }
    title.active_colorpicker = false

    function title:get( )
        return true
    end

    function title:set( new_name )
        self.name = new_name
    end

    function title:add_color_picker( gui_link, default_color )
        local picker = controls.new_colorpicker( self, gui_link, default_color )

        table.insert(
            self.colorpickers,
            picker
        )

        return picker
    end

    function title:get_height( )
        return font_height.controls + 5
    end

    function title:set_visible( new_state )
        self.visible = new_state
    end

    function title:handle( pos, width )
        local in_bounds = is_in_bounds( pos, vector( width, font_height.controls ) )

        self.visuals.hovering = in_bounds
    end

    function title:render( pos, width, should_handle )
        if pos.y >= self.subtab.tab.menu.pos.y then
            local title_start = pos + vector( self.subtab.tab.menu.padding.group.x / 2, 0)
            
            renderer.use_font( controls_font )
            renderer.text(
                title_start,
                self.visuals.hovering and global_colors.hovered_text or global_colors.disabled_text,
                self.name
            )

            -- render colorpickers
            local hovered_picker = nil
            self.active_colorpicker = nil
            for i = 1, #self.colorpickers do
                local picker = self.colorpickers[ i ]

                local x_offset = ( i - 1 ) * ( picker.size.menu.x + 5 )

                picker:render( pos, width - x_offset, should_handle )

                if not hovered_picker and picker:is_hovering( ) then
                    hovered_picker = picker
                elseif picker.open then
                    self.active_colorpicker = picker
                end
            end

            if hovered_picker and hovered_picker.open then
                self.active_colorpicker = hovered_picker
            end

            if should_handle and not self.active_colorpicker and not hovered_picker then
                self:handle( pos, width )
            end
        end
    end

    return title
end

function controls.new_text_area( subtab, group, name )
    local text_area = { }

    text_area.group = group
    text_area.name = name

    text_area.visible = true

    text_area.value = ''

    text_area.subtab = subtab

    text_area.visuals = {
        hovering = false
    }

    text_area.bg_size = vector( font_height.controls )

    text_area.is_input_mode = false

    text_area.callback_fn = nil

    function text_area:set_callback( fn )
        self.callback_fn = fn
    end


    function text_area:get( )
        return self.value
    end

    function text_area:set( new )
        self.value = new
    end

    function text_area:get_height( )
        return font_height.controls + 5
    end

    function text_area:set_visible( new_state )
        self.visible = new_state
    end

    function text_area:handle( pos, width )
        local in_bounds = is_in_bounds( pos, vector( width, font_height.controls ) )

        self.visuals.hovering = in_bounds

        local is_m1_clicked = input.is_button_pressed( MOUSE_LEFT )

        if in_bounds and is_m1_clicked then
            self.is_input_mode = not self.is_input_mode
        elseif not in_bounds and is_m1_clicked then
            self.is_input_mode = false
        end

        if self.is_input_mode then
            local key = input.get_writable_key( )

            if key then -- ! hell yeah nested if statements, i could do if this then return x3 BUT i might need to add code after this so wont work (also gotos are bad)
                if #key == 1 then
                    self.value = self.value .. key

                    if self.callback_fn then
                        self.callback_fn( self, key )
                    end
                else
                    key = key:upper( )
                    if key == 'ENTER' then
                        self.is_input_mode = false

                        if self.callback_fn then
                            self.callback_fn( self, key )
                        end
                    elseif key == 'BACKSPACE' then
                        self.value = string.sub( self.value, 0, #self.value - 1 )

                        if self.callback_fn then
                            self.callback_fn( self, key )
                        end
                    end
                end
            end
        end
    end

    function text_area:render( pos, width, should_handle )
        self.bg_size.x = width - self.subtab.tab.menu.padding.group.x

        if pos.y >= self.subtab.tab.menu.pos.y then
            local title_start = pos + vector( math.floor( self.subtab.tab.menu.padding.group.x / 2 ), 0)
            
            renderer.rect_filled(
                title_start,
                self.bg_size,
                global_colors.checkbox
            )

            renderer.use_font( controls_font )
            title_start.x = title_start.x + 5
            if #self.value == 0 then
                renderer.text(
                    title_start,
                    self.is_input_mode and global_colors.disabled_text or global_colors.highlight_hover,
                    self.name
                )
            else
                local val_text = self.value

                if self.is_input_mode then
                    val_text = val_text .. ( globals.RealTime( ) % 1 > .5 and '' or '_' )
                end

                renderer.text(
                    title_start,
                    self.is_input_mode and global_colors.hovered_text  or self.visuals.hovering and global_colors.disabled_text or global_colors.highlight_hover,
                    val_text
                )
            end

            if should_handle then
                self:handle( pos, width )
            end
        end
    end

    return text_area
end

function controls.new_slider( subtab, group, name, default_value, min, max, suffix, gui_link_str, dictionary )
    local slider = { }

    slider.group = group
    slider.name = name

    renderer.use_font( controls_font )
    slider.name_size = renderer.measure_text( name )

    slider.value = default_value
    slider.min = min
    slider.max = max
    slider.delta = slider.max - slider.min

    slider.visible = true

    slider.dictionary = dictionary == nil and { } or dictionary

    slider.suffix = suffix
    slider.has_middle_part = slider.min < 0 and slider.max > 0

    slider.gui = gui_link_str
    slider.callback_fn = nil

    slider.changing_value = false

    slider.box_size = vector( math.floor( font_height.controls * 1.2 ) )
    slider.box_check_pad = vector( 3 )
    slider.check_size = slider.box_size - slider.box_check_pad * 2

    slider.subtab = subtab

    slider.visuals = {
        hovering = false
    }

    if slider.gui then
        slider.value = gui.GetValue( gui_link_str )
    end

    function slider:get( )
        return self.value
    end

    function slider:set(  new_val)
        self.value = clamp( new_val, self.min, self.max )

        if self.callback_fn then
            self.callback_fn( self )
        end
    end

    function slider:get_height( )
        return math.floor( font_height.controls * 2.8 )
    end

    function slider:set_visible( new_state )
        self.visible = new_state
    end

    function slider:add_callback( fn )
        self.callback_fn = fn
    end

    function slider:click( relative_pc )
        relative_pc = relative_pc > 1 and 1 or relative_pc < 0 and 0 or relative_pc

        self.value = self.min + math.floor( self.delta * relative_pc )

        if self.gui then
            gui.SetValue( gui_link_str, self.value )
        end

        if self.callback_fn ~= nil then
            self.callback_fn( self )
        end
    end

    function slider:do_allow_further_handling( )
        return false
    end

    function slider:handle( pos, width )
        local in_bounds = is_in_bounds( pos, vector( width, self.box_size.y ) )
        local m1_down = input.is_key_down( MOUSE_LEFT )

        slider.visuals.hovering = in_bounds or self.changing_value

        if ( in_bounds and m1_down ) or self.changing_value then
            local x_pc = ( input.mouse_pos.x - pos.x ) / width
            self:click( x_pc )

            slider.changing_value = true
        end

        if not m1_down then
            self.changing_value = false
        end
    end

    function slider:render( pos, width, should_handle )
        self.box_size.x = width - self.subtab.tab.menu.padding.group.x
        local text_pos = pos + vector( self.subtab.tab.menu.padding.group.x / 2 , 0)

        if pos.y >= self.subtab.tab.menu.pos.y then
            -- render slider name
            renderer.use_font( controls_font )
            renderer.text(
                text_pos,
                self.state and accent_color_light or self.visuals.hovering and global_colors.hovered_text or global_colors.disabled_text,
                self.name
            )

            -- render hint text
            local hint_text = ( ' - %s%s' ):format( self.value, self.suffix == nil and '' or self.suffix )

            if self.dictionary[ self.value ] then
                hint_text = ( ' - %s' ):format( self.dictionary[ self.value ] )
            end

            renderer.text(
                text_pos + vector( self.name_size.x, 0 ),
                global_colors.hint_text,
                hint_text
            )
        end

        local slider_start = text_pos + vector( 0, math.floor( font_height.controls * 1.2 ) )

        if slider_start.y >= self.subtab.tab.menu.pos.y and slider_start.y + self.box_size.y <= self.subtab.tab.menu.pos.y + self.subtab.tab.menu.size.menu.y then
            if should_handle then
                self:handle( slider_start, self.box_size.x )
            end

            renderer.rect_filled(
                slider_start,
                self.box_size,
                global_colors.checkbox
            )

            if self.has_middle_part then
                local pc_filled = math.abs( self.value / self.delta )
                local filled_size = self.box_size - self.box_check_pad * 2
                local size = vector( math.floor( filled_size.x * pc_filled ), filled_size.y )

                local middle_pos_relative = ( ( self.box_size.x ) / self.delta ) * -self.min

                local start_pos = slider_start + self.box_check_pad + vector( middle_pos_relative, 0 )
                if self.value < 0 then
                    local width = math.floor( ( ( self.box_size.x ) / self.delta ) * math.abs( self.value ) )

                    size.x = width
                    start_pos.x = start_pos.x - width
                end

                renderer.rect_filled(
                    start_pos,
                    size - vector(  self.box_check_pad.x, 0 ),
                    accent_color_light
                )

                renderer.rect_filled(
                    slider_start + vector( middle_pos_relative - 1, 0 ),
                    vector( 3, self.box_size.y ),
                    self.subtab.tab.menu.colors.tab
                )

            else
                local pc_filled = self.value / self.delta
                local filled_size = self.box_size - self.box_check_pad * 2

                filled_size.x = math.floor( filled_size.x * pc_filled )

                renderer.rect_filled(
                    slider_start + self.box_check_pad,
                    filled_size,
                    accent_color_light
                )
            end
        end
    end

    return slider
end

function controls.new_combo( subtab, group, name, default_selected, gui_link_str, ... )
    local combo = { }
    combo.topmost = true

    combo.group = group
    combo.name = name

    renderer.use_font( controls_font )
    combo.name_size = renderer.measure_text( name )

    combo.selected = default_selected
    
    combo.visible = true

    combo.items = { ... }
    combo.item_height = math.floor( font_height.controls * 1.2 )

    combo.gui = gui_link_str
    combo.callback_fn = nil

    combo.open = false
    combo.in_open_menu_bounds = false

    combo.box_size = vector( math.floor( font_height.controls * 1.2 ) )
    combo.scrollwheel_size = vector( 5, 0 )

    combo.dropdown_size = vector( )

    combo.subtab = subtab

    combo.visuals = {
        hovering = false
    }

    combo.colorpickers = { }
    combo.active_colorpicker = false

    local max_combo_height = 250
    combo.dropdown_size.y = #combo.items * combo.item_height

    combo.needs_scrollwheel = combo.dropdown_size.y > max_combo_height
    combo.max_scroll_amount = 0

    if combo.needs_scrollwheel then
        combo.max_scroll_amount = combo.dropdown_size.y - max_combo_height
        combo.dropdown_size.y = max_combo_height
    end

    combo.scroll_amount = 0
    combo.scrolling = false

    if combo.gui then
        local gui_val = gui.GetValue( combo.gui )

        for i = 1, #combo.items do
            if combo.items[ i ] == gui_val then
                combo.selected = i
                break
            end
        end
    end

    function combo:get( )
        return self.selected, self.items[ self.selected ]
    end

    function combo:set_name( name )
        for i = 1, #self.items do
            if self.items[ i ] == name then
                self.selected = i
            end
        end
    end

    function combo:get_items( )
        return self.items
    end

    function combo:update( new_items, default_selected )
        self.selected = default_selected == nil and 1 or default_selected
        self.items = new_items

        self.dropdown_size.y = #self.items * self.item_height
        self.needs_scrollwheel = self.dropdown_size.y > max_combo_height
        self.max_scroll_amount = 0

        if self.needs_scrollwheel then
            self.max_scroll_amount = self.dropdown_size.y - max_combo_height
            self.dropdown_size.y = max_combo_height
        end
    end


    function combo:add_color_picker( gui_link, default_color )
        local picker = controls.new_colorpicker( self, gui_link, default_color )

        table.insert(
            self.colorpickers,
            picker
        )

        return picker
    end

    function combo:get_height( )
        return math.floor( font_height.controls * 2.8 )
    end

    function combo:add_callback( fn )
        self.callback_fn = fn
    end

    function combo:set_visible( new_state )
        self.visible = new_state
    end

    function combo:click( item_index )
        self.selected = item_index

        if self.gui then
            gui.SetValue( combo.gui, self.items[ item_index ] )
        end

        if self.callback_fn ~= nil then
            self.callback_fn( self )
        end

        self.open = false
    end

    function combo:do_allow_further_handling( )
        return not self.open
    end

    function combo:handle( pos, width )
        local in_bounds = is_in_bounds( pos, vector( width, self.box_size.y ) )
        local m1_pressed = input.is_button_pressed( MOUSE_LEFT )

        self.visuals.hovering = in_bounds or self.open

        if ( in_bounds and m1_pressed ) then
            self.open = not self.open
        end

        if not in_bounds and not self.in_open_menu_bounds and m1_pressed then
            self.open = false
        end
    end

    function combo:render_dropdown( pos )
        local combo_start = pos + vector( self.subtab.tab.menu.padding.group.x / 2 , math.floor( font_height.controls * 1.2 ) )

        local open_menu_start = combo_start + vector( 0, self.box_size.y )
        local open_menu_size = vector( self.box_size.x, self.dropdown_size.y )

        renderer.rect_filled(
            open_menu_start,
            open_menu_size,
            self.subtab.tab.menu.colors.tab
        )

        renderer.rect(
            open_menu_start,
            open_menu_size,
            global_colors.black
        )

        
        if self.needs_scrollwheel then
            self:render_scrollwheel( open_menu_start + vector( self.box_size.x - 5, 0 ) )
        end

        local item_idx_hovered

        if is_in_bounds( open_menu_start, open_menu_size ) then
            self.in_open_menu_bounds = true

            local y_pos_relative = input.mouse_pos.y - ( open_menu_start.y - self.scroll_amount  )
            item_idx_hovered = y_pos_relative // self.item_height + 1

            if item_idx_hovered > 0 and item_idx_hovered <= #self.items then
                local rect_start = open_menu_start + vector( 2, ( item_idx_hovered - 1 ) * self.item_height + 2 - self.scroll_amount )
                local rect_size = vector( self.box_size.x - ( self.needs_scrollwheel and 8 or 4 ), self.item_height - 4 )

                local r, g, b, a_o = color_mt.unpack( global_colors.highlight_hover )
                local a = a_o

                -- if hovering an appearing element
                if ( rect_start.y + self.item_height ) > ( open_menu_start.y + open_menu_size.y ) then
                    local diff = ( rect_start.y + self.item_height ) - ( open_menu_start.y + open_menu_size.y )

                    rect_start.y = open_menu_start.y + open_menu_size.y - self.item_height

                    local pc = 1 - ( diff / self.item_height )

                    a = math.floor( pc * a_o )

                    a = clamp( a, 0, a_o )
                end

                -- render highlight rect on item
                renderer.rect_filled(
                    rect_start,
                    rect_size,
                    color( r, g, b, a )
                )
            end

            local m1_pressed = input.is_button_pressed( MOUSE_LEFT )

            if item_idx_hovered > 0 and item_idx_hovered <= #self.items and m1_pressed and not self.scrolling then
                self:click( item_idx_hovered )
                -- self.scroll_amount = 0 -- dond resed on clos ok? понимаю хyесос ??????? SPASSIIIBA
            end
        else
            self.in_open_menu_bounds = false
        end

        -- render item names
        local index_start = 1
        local max_amount = #self.items
        local end_amt = index_start + max_amount - 1

        if self.needs_scrollwheel then
            index_start = self.scroll_amount // self.item_height + 1
            max_amount = self.dropdown_size.y // self.item_height
            end_amt = index_start + max_amount
        end

        for i = index_start, end_amt do
            local render_pos = open_menu_start + vector( 5, i * self.item_height - self.name_size.y - 2 - self.scroll_amount )

            renderer.use_font( self.selected == i and group_title_font or controls_font )

            local r, g, b, _ = color_mt.unpack( self.selected == i and accent_color_light or item_idx_hovered == i and global_colors.hovered_text or global_colors.disabled_text )
            local a = 255

            if end_amt == i then
                local diff = ( open_menu_start.y + open_menu_size.y ) - render_pos.y

                a = math.floor( diff / self.item_height * 255 )

                render_pos.y = open_menu_start.y + open_menu_size.y - self.name_size.y - 3

                a = clamp( a, 0, 255 )
            end

            renderer.text(
                render_pos,
                color( r, g, b, a ),
                self.items[ i ]
            )
        end

        -- re-render the box and selected (yes this is suboptimal but i really cant rewrite the logic i did 2 weeks ago)
        if combo_start.y >= self.subtab.tab.menu.pos.y then
            if combo_start.y + self.box_size.y < self.subtab.tab.menu.pos.y + self.subtab.tab.menu.size.menu.y then
                renderer.rect_filled(
                    combo_start,
                    self.box_size,
                    global_colors.checkbox
                )

                -- render selected text
                renderer.use_font( controls_font )
                renderer.text(
                    combo_start + vector( 5, self.box_size.y - self.name_size.y - 2 ),
                    self.visuals.hovering and global_colors.hovered_text or global_colors.disabled_text,
                    self.items[ self.selected ]
                )
            end
        end
    end

    function combo:render_scrollwheel( pos )
        local scroll_amount_in_pixels = self.scroll_amount
        local total_scrollwheel_height = self.max_scroll_amount + max_combo_height
        local scrollwheel_visual_height = self.dropdown_size.y
        local scrollwheel_height = math.floor( ( self.dropdown_size.y / total_scrollwheel_height ) * scrollwheel_visual_height )

        local scroll_amount_pc = clamp( scroll_amount_in_pixels / self.max_scroll_amount, 0, 1 )

        local visual_offset_y = math.floor( ( scrollwheel_visual_height - scrollwheel_height ) * scroll_amount_pc )

        local head_pos = vector( pos.x, pos.y + visual_offset_y )
        local head_size = vector( self.scrollwheel_size.x, scrollwheel_height )

        local m1_down = input.is_key_down( MOUSE_LEFT )
        local in_bounds = is_in_bounds( head_pos, head_size )

        if ( m1_down and in_bounds ) and not self.scrolling then
            self.scrolling = true

            self.scrollbar_offset = input.mouse_pos - head_pos
        end

        if self.scrolling then
            head_pos.y = input.mouse_pos.y - self.scrollbar_offset.y

            head_pos.y = clamp( head_pos.y, pos.y, pos.y + scrollwheel_visual_height - scrollwheel_height )

            local visual_offset_from_top = head_pos.y - pos.y

            local pc_climbed = visual_offset_from_top / ( scrollwheel_visual_height - scrollwheel_height )

            pc_climbed = clamp( pc_climbed, 0, 1 )
            
            self.scroll_amount = math.floor( pc_climbed * self.max_scroll_amount )
        end

        if self.scrolling and not m1_down then
            self.scrolling = false
        end

        renderer.rect_filled(
            pos,
            vector( self.scrollwheel_size.x, scrollwheel_visual_height ),
            global_colors.black
        )

        renderer.rect_filled(
            head_pos,
            head_size,
            color( 255, 100 )
        )
    end

    function combo:render( pos, width, should_handle )
        self.box_size.x = width - self.subtab.tab.menu.padding.group.x

        -- render combo name
        local text_pos = pos + vector( self.subtab.tab.menu.padding.group.x / 2 , 0)
        if text_pos.y >= self.subtab.tab.menu.pos.y then
            renderer.use_font( controls_font )
            renderer.text(
                text_pos,
                self.state and accent_color_light or self.visuals.hovering and global_colors.hovered_text or global_colors.disabled_text,
                self.name
            )

             -- render colorpickers
             local hovered_picker = nil
             self.active_colorpicker = nil
             for i = 1, #self.colorpickers do
                 local picker = self.colorpickers[ i ]
 
                 local x_offset = ( i - 1 ) * ( picker.size.menu.x + 5 )
 
                 picker:render( pos, width - x_offset, should_handle )
 
                 if not hovered_picker and picker:is_hovering( ) then
                     hovered_picker = picker
                 end
                 
                 if picker.open then
                     self.active_colorpicker = picker
                 end
             end
 
            --  if hovered_picker and hovered_picker.open then
            --      self.active_colorpicker = hovered_picker
            --  end
        end

        local combo_start = text_pos + vector( 0, math.floor( font_height.controls * 1.2 ) )
        if combo_start.y >= self.subtab.tab.menu.pos.y then
            if should_handle and not self.active_colorpicker then
                self:handle( combo_start, self.box_size.x )
            end

            if combo_start.y + self.box_size.y < self.subtab.tab.menu.pos.y + self.subtab.tab.menu.size.menu.y then
                renderer.rect_filled(
                    combo_start,
                    self.box_size,
                    global_colors.checkbox
                )

                -- render selected text
                renderer.use_font( controls_font )
                renderer.text(
                    combo_start + vector( 5, self.box_size.y - self.name_size.y - 2 ),
                    self.visuals.hovering and global_colors.hovered_text or global_colors.disabled_text,
                    self.items[ self.selected ]
                )
            end
        end
    end

    return combo
end

function controls.new_multicombo( subtab, group, name, ... )
    local combo = { }
    combo.topmost = true

    combo.group = group
    combo.name = name

    combo.preview_text = '-'

    renderer.use_font( controls_font )
    combo.name_size = renderer.measure_text( name )
    
    combo.items = { ... }
    combo.selected = { }

    combo.item_height = math.floor( font_height.controls * 1.2 )

    combo.callback_fn = nil

    combo.open = false
    combo.in_open_menu_bounds = false

    combo.box_size = vector( math.floor( font_height.controls * 1.2 ) )

    combo.subtab = subtab

    combo.visible = true

    combo.visuals = {
        hovering = false
    }

    function combo:set( index, selected )
        self.selected[ index ] = selected

        if self.callback_fn then
            self.callback_fn( self )
        end
    end

    function combo:get_height( )
        return math.floor( font_height.controls * 2.8 )
    end

    function combo:add_callback( fn )
        self.callback_fn = fn
    end

    function combo:set_visible( new_state )
        self.visible = new_state
    end

    function combo:get( name )
        for i = 1, #self.items do
            if self.items[ i ] == name then
                return self.selected[ i ]
            end
        end
    end

    function combo:do_allow_further_handling( )
        return not self.open
    end

    function combo:click( item_index )
        local val = self.selected[ item_index ]
        if val == nil then
            self.selected[ item_index ] = true
        else
            self.selected[ item_index ] = not val
        end

        if self.callback_fn ~= nil then
            self.callback_fn( self )
        end

        local selected = { }
        for i = 1, #self.items do
            if self.selected[ i ] then
                table.insert( selected, self.items[ i ] )
            end
        end

        if #selected == 0 then
            selected = { '-' }
        end

        self.preview_text = table.concat( selected, ', ' )

        local text_width = renderer.measure_text( self.preview_text ).x

        -- bruteforce the right amount of text to show
        local text_to_show = { selected[ 1 ] }
        if text_width > self.box_size.x then
            for i = 2, #selected do
                table.insert( text_to_show, selected[ i ] )
                local new_text = table.concat( text_to_show, ', ' )

                local new_width = renderer.measure_text( new_text ).x

                if new_width > self.box_size.x - 25 then -- generous amount of padding
                    table.remove( text_to_show, #text_to_show )

                    self.preview_text = table.concat( text_to_show, ', ' ) .. ( ' +%i' ):format( #selected - i + 1 )
                    break
                end
            end
        end
    end

    function combo:handle( pos, width )
        local in_bounds = is_in_bounds( pos, vector( width, self.box_size.y ) )
        local m1_pressed = input.is_button_pressed( MOUSE_LEFT )

        self.visuals.hovering = in_bounds or self.open

        if ( in_bounds and m1_pressed ) then
            self.open = not self.open
        end

        if not in_bounds and not self.in_open_menu_bounds and m1_pressed then
            self.open = false
        end
    end

    function combo:render_dropdown( pos )
        local combo_start = pos + vector( self.subtab.tab.menu.padding.group.x / 2 , math.floor( font_height.controls * 1.2 ) )

        local open_menu_start = combo_start + vector( 0, self.box_size.y )
        local open_menu_size = vector( self.box_size.x, #self.items * self.item_height )

        renderer.rect_filled(
            open_menu_start,
            open_menu_size,
            self.subtab.tab.menu.colors.tab
        )

        local item_idx_hovered

        if is_in_bounds( open_menu_start, open_menu_size ) then
            self.in_open_menu_bounds = true

            local y_pos_relative = input.mouse_pos.y - open_menu_start.y
            item_idx_hovered = y_pos_relative // self.item_height + 1
            -- render highlight rect on item
            renderer.rect_filled(
                open_menu_start + vector( 2, ( item_idx_hovered - 1 ) * self.item_height + 2 ),
                vector( self.box_size.x - 4, self.item_height - 4 ),
                global_colors.highlight_hover
            )

            local m1_pressed = input.is_button_pressed( MOUSE_LEFT )


            if item_idx_hovered > 0 and item_idx_hovered <= #self.items and m1_pressed then
                self:click( item_idx_hovered )
            end
        else
            self.in_open_menu_bounds = false
        end

        -- render item names
        for i = 1, #self.items do
            local render_pos = open_menu_start + vector( 5, i * self.item_height - self.name_size.y - 2 )

            renderer.use_font( self.selected[ i ] and group_title_font or controls_font )
            renderer.text(
                render_pos,
                self.selected[ i ] and accent_color_light or item_idx_hovered == i and global_colors.hovered_text or global_colors.disabled_text,
                self.items[ i ]
            )
        end
    end

    function combo:render( pos, width, should_handle )
        self.box_size.x = width - self.subtab.tab.menu.padding.group.x

        -- render combo name
        local text_pos = pos + vector( self.subtab.tab.menu.padding.group.x / 2 , 0)
        if text_pos.y >= self.subtab.tab.menu.pos.y then
            renderer.use_font( controls_font )
            renderer.text(
                text_pos,
                self.state and accent_color_light or self.visuals.hovering and global_colors.hovered_text or global_colors.disabled_text,
                self.name
            )
        end

        local combo_start = text_pos + vector( 0, math.floor( font_height.controls * 1.2 ) )

        if combo_start.y >= self.subtab.tab.menu.pos.y then
            if should_handle then
                self:handle( combo_start, self.box_size.x )
            end

            renderer.rect_filled(
                combo_start,
                self.box_size,
                global_colors.checkbox
            )

            -- render selected text
            renderer.text(
                combo_start + vector( 5, self.box_size.y - self.name_size.y - 2 ),
                self.visuals.hovering and global_colors.hovered_text or global_colors.disabled_text,
                self.preview_text
            )
        end
    end

    return combo
end

function controls.new_subtab( tab_obj, name )
    local subtab = { }

    subtab.name = name
    subtab.tab = tab_obj

    renderer.use_font( subtab_font )
    subtab.text_size = renderer.measure_text( subtab.name )

    subtab.padding = {
        text = vector( 15, 0 )
    }

    function subtab:add_text( group, name )
        local text_obj = controls.new_text( self, group, name )

        subtab.tab.menu:_add_control( text_obj )

        return text_obj
    end

    function subtab:add_checkbox( group, name, default_state, gui_link_str )
        local checkbox_obj = controls.new_checkbox( self, group, name, default_state, gui_link_str )

        subtab.tab.menu:_add_control( checkbox_obj )

        return checkbox_obj
    end

    function subtab:add_button( group, name )
        local button_obj = controls.new_button( subtab, group, name )

        subtab.tab.menu:_add_control( button_obj )

        return button_obj
    end

    function subtab:add_text_area( group, name )
        local text_area_obj = controls.new_text_area( subtab, group, name )

        subtab.tab.menu:_add_control( text_area_obj )

        return text_area_obj
    end

    function subtab:add_slider( group, name, default_value, min, max, suffix, gui_link_str, dict )
        local slider_obj = controls.new_slider( self, group, name, default_value, min, max, suffix, gui_link_str, dict )

        subtab.tab.menu:_add_control( slider_obj )

        return slider_obj
    end

    function subtab:add_combo( group, name, default_selected, gui_link_str, ... )
        local combo_obj = controls.new_combo( self, group, name, default_selected, gui_link_str, ... )

        subtab.tab.menu:_add_control( combo_obj )

        return combo_obj
    end

    function subtab:add_multicombo( group, name, ... )
        local multicombo_obj = controls.new_multicombo( self, group, name, ... )

        subtab.tab.menu:_add_control( multicombo_obj )

        return multicombo_obj
    end

    function subtab:render( pos, sz, isactive )
        if isactive then
            renderer.rect_fade_single_color(
                pos, sz, accent_color_light, 0, 50, true
            )
        end

        local text_start = pos + vector( self.padding.text.x, sz.y / 2 - self.text_size.y / 2 - 2 )
        renderer.use_font( subtab_font )
        renderer.text(
            text_start, isactive and accent_color_light or global_colors.hovered_text, self.name
        )
    end

    return subtab
end

function controls.new_tab( menu_obj, name )
    local tab = { }

    tab.name = name
    tab.menu = menu_obj

    function tab:add_subtab( subtab_name )
        if self.menu:has_subtab( subtab_name ) then
            return error( ( '[error] subtab "%s" already exists.' ):format( subtab_name ) )
        end

        local subtab_obj = controls.new_subtab( self, subtab_name )

        self.menu:_add_subtab( subtab_obj )

        return subtab_obj
    end

    function tab:render( pos, sz, is_active )
        if not menu_tab_icons[ tab.name ] then
            renderer.rect_filled(
                pos,
                sz,
                color( 100 )
            )
        else
            menu_tab_icons[ tab.name ]:render( pos, sz, is_active )
        end
    end

    return tab
end

function controls.create_menu( )
    local menu = { }

    menu.id = generate_id( )

    menu.tabs = { }
    menu.subtabs = new_orderer_table( )
    menu.items = new_orderer_table( )

    menu.active_tab = 1
    menu.cached_subtabs = { }
    menu.cached_scrolls = { }

    menu.open = { }

    menu.pos = vector( 100, 100 )
    menu.size = {
        menu = vector( 700, 500 ),
        tab = vector( 80, 500 ),
    }

    menu.size.subtab = vector( menu.size.tab.x + 135, 500 )

    menu.size.tab_icon = vector( math.floor( menu.size.tab.x / 6 * 4 ) )
    menu.size.subtab_row = vector( menu.size.subtab.x - menu.size.tab.x, 40 )

    menu.padding = {
        subtab = vector( 5, math.floor( menu.size.tab.x / 12 ) ),
        tab_icon = vector( math.floor(menu.size.tab.x / 6 ), math.floor( menu.size.tab.x / 12 ) ),
        group = vector( 10, 26 )
    }

    menu.size.subtab_row.x = menu.size.subtab_row.x - menu.padding.subtab.x
    menu.size.group = vector( math.floor( ( menu.size.menu.x - menu.size.subtab_row.x - menu.padding.subtab.x - menu.size.tab.x - menu.padding.group.x * 3 ) / 2 + 0.5 ), 0 )
    menu.size.group_base = vector( 0, font_height.group_title + menu.padding.group.y )

    menu.size.scrollwheel = vector( 5, menu.size.menu.y - 5 - 5 )
    menu.scrollwheel_pos = menu.pos + vector( menu.size.menu.x - 5 - menu.size.scrollwheel.x, menu.size.scrollwheel.x )

    menu.open = true
    menu.can_scroll = true

    menu.colors = {
        bg = color( 28 ),
        tab = color( 44 ),
        subtab = color( 51 ),

        tab_shadow = color( 0, 120 ),
        subtab_shadow = color( 0, 120 ),
    }

    menu.group_images = { }

    function menu:add_group_image( tab_name, subtab_name, group_name, texture_id )
        if not self.group_images[ tab_name ] then
            self.group_images[ tab_name ] = { }
        end

        if not self.group_images[ tab_name ][ subtab_name ] then
            self.group_images[ tab_name ][ subtab_name ] = { }
        end

        if not self.group_images[ tab_name ][ subtab_name ][ group_name ] then
            self.group_images[ tab_name ][ subtab_name ][ group_name ] = texture_id
        end
    end

    function menu:has_subtab( subtab_name )
        for _, tab_tbl in pairs( self.subtabs:get_values( ) ) do
            for i = 1, #tab_tbl do
                if tab_tbl[ i ].name == subtab_name then return end
            end
        end

        return false
    end

    function menu:has_tab( tab_name )
        for i = 1, #self.tabs do
            if self.tabs[ i ].name == tab_name then return end
        end
        return false
    end

    function menu:_add_control( control_obj )
        local tab_name = control_obj.subtab.tab.name
        local subtab_name = control_obj.subtab.name
        local group = control_obj.group

        if self.items[ tab_name ] == nil then
            self.items[ tab_name ] = { } -- { [ subtab_name ] = { [ group ] = { control_obj } } }
            self.cached_subtabs[ tab_name ] = subtab_name
            self.cached_scrolls[ tab_name ] = { }
        end

        -- if subtab doesnt exist
        if self.items[ tab_name ][ subtab_name ] == nil then
            self.items[ tab_name ][ subtab_name ] = new_orderer_table( ) -- { [ group ] = control_obj }
            self.cached_scrolls[ tab_name ][ subtab_name ] = 0
        end

        -- ok subtab exists
        -- do we append to existing group or create a new one
        if self.items[ tab_name ][ subtab_name ][ group ] == nil then
            self.items[ tab_name ][ subtab_name ][ group ] = { } -- { control_obj }
        end

        -- group exists, append to existing group
        table.insert(
            self.items[ tab_name ][ subtab_name ][ group ],
            control_obj
        )
    end

    function menu:_add_subtab( subtab_obj )
        if not self.subtabs[ subtab_obj.tab.name ] then
            self.subtabs[ subtab_obj.tab.name ] = new_orderer_table( )
            self.cached_subtabs[ subtab_obj.tab.name ] = subtab_obj.name
        end

        self.subtabs[ subtab_obj.tab.name ][ subtab_obj.name ] = subtab_obj
    end

    function menu:add_tab( tab_name )
        if self:has_tab( tab_name ) then
            return error( ( '[error] tab "%s" already exists.' ):format( tab_name ) )
        end

        local tab = controls.new_tab( self, tab_name )

        self.tabs[ #self.tabs + 1 ] = tab

        if debug.setup then
            print( ( '[setup]\tadded tab "%s"' ):format( tab_name ) )
        end

        return tab
    end

    function menu:render_background( )
        renderer.rect_filled( -- bg
            self.pos,
            self.size.menu,
            self.colors.bg
        )

        renderer.rect_filled( -- subtab
            self.pos,
            self.size.subtab,
            self.colors.subtab
        )

        -- subtab shadow
        renderer.rect_fade_single_color(
            self.pos + vector( self.size.subtab.x, 0 ),
            vector( 10, self.size.subtab.y ),
            self.colors.subtab_shadow,
            255, 0, true
        )

        renderer.rect_filled( -- tab
            self.pos,
            self.size.tab,
            self.colors.tab
        )

        -- tab shadow
        renderer.rect_fade_single_color(
            self.pos + vector( self.size.tab.x, 0 ),
            vector( 10, self.size.tab.y ),
            self.colors.tab_shadow,
            255, 0, true
        )

        -- render menu outline
        local intersection = get_intersect( self.pos, self.size.menu )

        render_wrapping_gradient(
            self.pos,
            self.size.menu,
            intersection,
            500,
            2,
            'left',
            accent_color
        )

        render_wrapping_gradient( 
            self.pos,
            self.size.menu,
            intersection,
            500,
            2,
            'right',
            accent_color
        )
    end

    function menu:render_tabs( )
        local tabs_render_start = self.pos + self.padding.tab_icon
        for i = 1, #self.tabs do
            self.tabs[ i ]:render( tabs_render_start, self.size.tab_icon, i == self.active_tab )

            tabs_render_start.y = tabs_render_start.y + self.size.tab_icon.y + self.padding.tab_icon.y
        end

        local is_m1_clicked = input.is_button_pressed( MOUSE_LEFT )

        if is_m1_clicked then
            -- check if mouse x in area
            if input.mouse_pos.x >= self.pos.x and input.mouse_pos.x <= self.pos.x + self.size.tab.x then
                -- calculate new tab idx
                local relative_y = input.mouse_pos.y - ( self.pos.y + self.padding.tab_icon.y )
                
                local idx = relative_y // ( self.size.tab_icon.y + self.padding.tab_icon.y ) + 1

                if idx > 0 and idx <= #self.tabs then
                    self.active_tab = idx

                    if debug.tab then
                        print( ( '[tab]\tselected new tab index %s (found name "%s")' ):format( idx, self.tabs[ idx ].name ) )
                    end
                end
            end
        end

        -- render move icon
        local hover_pos = self.pos + vector( 0, self.size.menu.y - self.size.tab_icon.x )
        local hover_size = self.size.tab_icon

        local in_hover_bounds = is_in_bounds( hover_pos, hover_size )
        local is_m1_down = input.is_key_down( MOUSE_LEFT )

        if is_m1_down and in_hover_bounds and not self.dragging then
            self.dragging_difference = input.mouse_pos - self.pos
            self.dragging = true
        end

        if self.dragging then
            self.pos = input.mouse_pos - self.dragging_difference
            self.scrollwheel_pos = menu.pos + vector( menu.size.menu.x - 5 - menu.size.scrollwheel.x, menu.size.scrollwheel.x )
        end

        if not is_m1_down then
            self.dragging = false
        end

        menu_tab_icons.move:render(
            hover_pos, hover_size, in_hover_bounds
        )
    end

    function menu:render_subtabs( )
        local active_tab = self.tabs[ self.active_tab ]
        local subtabs = self.subtabs[ active_tab.name ]

        if not subtabs then
            return false
        end

        subtabs = subtabs:get_values( )

        local render_start = self.pos + vector( self.size.tab.x + self.padding.subtab.x, self.padding.subtab.y )
        local active = false
        for i = 1, #subtabs do
            active = self.cached_subtabs[ active_tab.name ] == subtabs[ i ].name

            subtabs[ i ]:render( render_start, self.size.subtab_row, active )

            render_start.y = render_start.y + self.size.subtab_row.y
            active = false
        end

        local is_m1_clicked = input.is_button_pressed( MOUSE_LEFT )

        if is_m1_clicked then
            -- check if mouse x in area
            if input.mouse_pos.x >= render_start.x and input.mouse_pos.x <= render_start.x + self.size.subtab_row.x then
                -- calculate new subtab
                local relative_y = input.mouse_pos.y - ( self.pos.y + self.padding.subtab.y )
                
                local idx = relative_y // ( self.size.subtab_row.y ) + 1

                if idx > 0 and idx <= #subtabs then
                    self.cached_subtabs[ active_tab.name ] = subtabs[ idx ].name

                    if debug.tab then
                        print( ( '[tab]\tselected new subtab index %s ("%s")' ):format( idx, subtabs[ idx ].name ) )
                    end
                end
            end
        end

        return true
    end

    function menu:render_scrollwheel( tab_obj, subtab_obj, amount_of_px_over )
        local tab_name = tab_obj.name
        local subtab_name = subtab_obj.name

        local scroll_amount_in_pixels = self.cached_scrolls[ tab_name ][ subtab_name ]
        local total_scrollwheel_height = self.size.menu.y + amount_of_px_over
        local scrollwheel_visual_height = menu.size.scrollwheel.y
        local scrollwheel_height = math.floor( ( self.size.menu.y / total_scrollwheel_height ) * scrollwheel_visual_height )

        local scroll_amount_pc = clamp( scroll_amount_in_pixels / amount_of_px_over, 0, 1 )

        local visual_offset_y = math.floor( ( scrollwheel_visual_height - scrollwheel_height ) * scroll_amount_pc )

        local head_pos = vector( self.scrollwheel_pos.x, self.scrollwheel_pos.y + visual_offset_y )
        local head_size = vector( self.size.scrollwheel.x, scrollwheel_height )

        local m1_down = input.is_key_down( MOUSE_LEFT )
        local in_bounds = is_in_bounds( head_pos, head_size )

        if ( m1_down and in_bounds ) and not self.scrolling then
            self.scrolling = true

            self.scrollbar_offset = input.mouse_pos - head_pos
        end

        if self.scrolling then
            head_pos.y = input.mouse_pos.y - self.scrollbar_offset.y

            head_pos.y = clamp( head_pos.y, self.scrollwheel_pos.y, self.scrollwheel_pos.y + scrollwheel_visual_height - scrollwheel_height )

            local visual_offset_from_top = head_pos.y - self.scrollwheel_pos.y

            local pc_climbed = visual_offset_from_top / ( scrollwheel_visual_height - scrollwheel_height )

            pc_climbed = clamp( pc_climbed, 0, 1 )
            
            self.cached_scrolls[ tab_name ][ subtab_name ] = math.floor( pc_climbed * amount_of_px_over )
        end

        if self.scrolling and not m1_down then
            self.scrolling = false
        end

        renderer.rect_filled(
            self.scrollwheel_pos,
            vector( self.size.scrollwheel.x, scrollwheel_visual_height ),
            global_colors.black
        )

        renderer.rect_filled(
            head_pos,
            head_size,
            color( 255, 100 )
        )
    end

    function menu:render_current_location( )
        local active_tab = self.tabs[ self.active_tab ]
        local subtab_name = self.cached_subtabs[ active_tab.name ]

        local text = ( 'bettergui > %s > %s' ):format( active_tab.name, subtab_name )
        local text_start = vector( self.pos.x + self.size.subtab.x + 5, self.pos.y )

        renderer.use_font( group_title_font )
        renderer.text(
            text_start,
            global_colors.hint_text,
            text
        )
    end

    function menu:render_groups( )
        local active_tab = self.tabs[ self.active_tab ]
        local subtab_name = self.cached_subtabs[ active_tab.name ]
        local subtab_obj = self.subtabs[ active_tab.name ][ subtab_name ]

        local tab_name = active_tab.name

        if not self.items[ tab_name ] or not self.items[ tab_name ][ subtab_name ] then
            self:render_current_location( )
            return
        end

        -- get left group heights
        local heights = { left = { }, right = { } }
        local skip = { left = { }, right = { } }

        local group_names = self.items[ tab_name ][ subtab_name ]:get_keys( )

        for i = 1, #group_names do
            local group_name = group_names[ i ]

            local group_items = self.items[ tab_name ][ subtab_obj.name ][ group_name ]

            local height = menu.size.group_base.y + 10 -- 10 px at the end ))))))
            for item_idx = 1, #group_items do
                local opt = group_items[ item_idx ]

                if opt.visible then
                    height = height + group_items[ item_idx ]:get_height( )
                end
            end

            if height == self.size.group_base.y + 10 then
                skip[ i % 2 == 0 and 'right' or 'left' ][ i ] = true
            else
                table.insert(
                    heights[ i % 2 == 0 and 'right' or 'left' ],
                    height
                )
            end
        end

        local needs_scollwheel = false
        local sum_height = 0
        local biggest_height = 0
        for _, heights_tbl in pairs( heights ) do
            sum_height = self.padding.group.y * 4
            for i = 1, #heights_tbl do
                sum_height = sum_height + heights_tbl[ i ]
            end

            if sum_height > self.size.menu.y then
                needs_scollwheel = true

                if sum_height > biggest_height then
                    biggest_height = sum_height
                end

                break
            end
        end

        sum_height = biggest_height

        -- render left groups
        local left_group_start = vector(
            self.pos.x + self.size.subtab.x + self.padding.group.x, self.pos.y + self.padding.group.y
        )

        -- render right groups
        local right_group_start = vector(
            self.pos.x + self.size.subtab.x + self.padding.group.x * 2 + self.size.group.x, self.pos.y + self.padding.group.y
        )

        local render_after
        local do_handle = not self.scrolling
        self.can_scroll = true

        for i = 1, #group_names, 1 do
            local do_right = i % 2 == 0
            local skip_tbl = do_right and skip.right or skip.left
            local heights_tbl = do_right and heights.right or heights.left
            local idx = do_right and math.floor( i / 2 ) or math.floor( ( i - 1 ) / 2 + 1 )
            local start = do_right and right_group_start or left_group_start

            if not skip_tbl[ idx ] then
                local group_name = group_names[ i ]

                -- render group background
                local group_height = heights_tbl[ idx ]

                if group_height then                    
                    local group_size = vector( self.size.group.x, group_height )

                    local group_start = vector( start.x, start.y )

                    if needs_scollwheel then
                        group_start.y = group_start.y - self.cached_scrolls[ tab_name ][ subtab_name ]
                    end

                    local bg_pos = vector( group_start.x, group_start.y )
                    local bg_size = vector( group_size.x, group_size.y )
                    local fix_y = 0
                    if group_start.y < self.pos.y then
                        fix_y = self.pos.y - group_start.y

                        bg_pos.y = bg_pos.y + fix_y
                        bg_size.y = bg_size.y - fix_y
                    end
                    
                    if group_start.y + group_size.y > self.pos.y + self.size.menu.y then
                        fix_y = ( group_start.y + group_size.y ) - ( self.pos.y + self.size.menu.y )
                        bg_size.y = bg_size.y - fix_y
                    end

                    if bg_pos.y + bg_size.y > self.pos.y then
                        renderer.rect_filled(
                            bg_pos,
                            bg_size,
                            self.colors.subtab
                        )


                        --! todo: fix bug, this will result in not enough memory due to how i handle group sizes (group size is small, this goes monkey mode)
                        --render group outline
                        local intersection = get_intersect( bg_pos, bg_size )

                        render_wrapping_gradient(
                            bg_pos,
                            bg_size,
                            intersection,
                            math.floor( ( bg_size.x + bg_size.y ) / 2 ),
                            1,
                            'left',
                            accent_color
                        )

                        render_wrapping_gradient(
                            bg_pos,
                            bg_size,
                            intersection,
                            math.floor( ( bg_size.x + bg_size.y ) / 2 ),
                            1,
                            'right',
                            accent_color
                        )
                    end

                    -- render group text
                    renderer.use_font( group_title_font )
                    local title_pos = group_start + ( self.padding.group / 2 )
                    if self.pos.y < title_pos.y and title_pos.y < self.pos.y + self.size.menu.y - font_height.group_title then
                        -- if group image exists, render it
                        local used_group_name = group_name
                        if self.group_images[ active_tab.name ] and
                           self.group_images[ active_tab.name ][ subtab_name ] and
                           self.group_images[ active_tab.name ][ subtab_name ][ group_name ] then
                            local group_texture_id = self.group_images[ active_tab.name ][ subtab_name ][ group_name ]

                            renderer.textured_rect(
                                title_pos,
                                vector( font_height.controls ),
                                group_texture_id
                            )

                            title_pos.x = title_pos.x + font_height.controls + 2

                            used_group_name = ( ' - %s' ):format( group_name )
                        end

                        renderer.text(
                            title_pos,
                            global_colors.disabled_text,
                            used_group_name
                        )
                    end

                    local control_start = group_start + vector( 0, menu.size.group_base.y )
                    local group_items = self.items[ tab_name ][ subtab_obj.name ][ group_name ]

                    for control_idx = 1, #group_items do
                        local control = group_items[ control_idx ]

                        if control.visible then
                            local control_height = control:get_height( )
                            if control_start.y + control_height > self.pos.y and control_start.y + font_height.controls <= self.pos.y + self.size.menu.y then
                                control:render( control_start, self.size.group.x, do_handle and control_start.y + control_height <= self.pos.y + self.size.menu.y )

                                local copy_control = control
                                if control.active_colorpicker ~= nil then
                                    copy_control = control.active_colorpicker
                                end

                                if copy_control.topmost then
                                    if copy_control.open then
                                        if do_handle and not copy_control:do_allow_further_handling( ) then
                                            do_handle = false
                                        end

                                        render_after = {
                                            pos = vector( control_start.x, control_start.y ),
                                            size = self.size.group.x,
                                            control = copy_control
                                        }
                                    end
                                end
                            end

                            control_start.y = control_start.y + control_height
                        end
                        
                    end

                    if do_right then
                        right_group_start.y = right_group_start.y + group_height + self.padding.group.y
                    else
                        left_group_start.y = left_group_start.y + group_height + self.padding.group.y
                    end
                end
            end
        end

        if needs_scollwheel then
            self:render_scrollwheel( active_tab, subtab_obj, sum_height - self.size.menu.y )
        end

        self:render_gradients( { tab = active_tab, subtab = subtab_obj } )

        if render_after then
            render_after.control:render_dropdown( render_after.pos, render_after.size )
        end
    end

    function menu:render_gradients( data )
        local group_menu_start = vector(
            self.pos.x + self.size.subtab.x, self.pos.y
        )

        local size = vector( menu.size.menu.x - menu.size.subtab_row.x - menu.padding.subtab.x - menu.size.tab.x, math.floor( self.padding.group.y / 2 ) )
        local size_gradient = vector( size.x, math.floor( self.padding.group.y / 2 ) )
        renderer.rect_filled(
            group_menu_start,
            size,
            self.colors.bg
        )

        -- render gradient
        renderer.rect_fade_single_color(
            group_menu_start + vector( 0, size.y ),
            size_gradient,
            self.colors.bg, 255, 0, false
        )

        group_menu_start.y = group_menu_start.y + self.size.menu.y - size.y - size_gradient.y

        -- render gradient
        renderer.rect_fade_single_color(
            group_menu_start,
            size_gradient,
            self.colors.bg, 0, 255, false
        )

        renderer.rect_filled(
            group_menu_start + vector( 0, size_gradient.y ),
            size,
            self.colors.bg
        )

        self:render_current_location( )
    end

    function menu:handle( )
    
    end

    function menu:render( )
        if input.is_button_pressed( KEY_DELETE ) then
            self.open = not self.open
        end

        if self.open then
            self:render_background( )
            self:render_tabs( )
            local should_render_groups = self:render_subtabs( )

            if should_render_groups then
                self:render_groups( )
            end
        end
    end

    return menu
end


local created_menu = controls.create_menu( )

local tab = {
    rage = created_menu:add_tab( 'rage' ),
    legit = created_menu:add_tab( 'legit' ),
    antiaim = created_menu:add_tab( 'antiaim' ),
    esp = created_menu:add_tab( 'esp' ),
    misc = created_menu:add_tab( 'misc' ),
}

local subtab = {
    rage = {
        main = tab.rage:add_subtab( 'main' ),
    },
    legit = {
        main = tab.legit:add_subtab( 'main' ),
    },
    antiaim = {
        generic = tab.antiaim:add_subtab( 'generic' ),

        scout = tab.antiaim:add_subtab( 'scout' ),
        soldier = tab.antiaim:add_subtab( 'soldier' ),
        pyro = tab.antiaim:add_subtab( 'pyro' ),

        demo = tab.antiaim:add_subtab( 'demo' ),
        heavy = tab.antiaim:add_subtab( 'heavy' ),
        engineer = tab.antiaim:add_subtab( 'engineer' ),

        medic = tab.antiaim:add_subtab( 'medic' ),
        sniper = tab.antiaim:add_subtab( 'sniper' ),
        spy = tab.antiaim:add_subtab( 'spy' ),
    },
    esp = {
        esp = tab.esp:add_subtab( 'esp' ),
        chams = tab.esp:add_subtab( 'chams' ),
        glow = tab.esp:add_subtab( 'glow' ),
        world = tab.esp:add_subtab( 'world' ),
    },
    misc = {
        general = tab.misc:add_subtab( 'general' ),
        helpers = tab.misc:add_subtab( 'helpers' )
    }
}

local element = {
    rage = {

    },
    legit = {

    },
    antiaim = { }, -- dynamically set up later
    esp = {
        override_esp = subtab.esp.esp:add_checkbox( 'custom esp', 'override lmaobox esp' ),

        override_chams = subtab.esp.chams:add_checkbox( 'custom chams', 'enable custom chams' ),
        subtab.esp.chams:add_text( 'custom chams', 'This will reset your chams' ),
        subtab.esp.chams:add_text( 'custom chams', 'settings for default lmaobox!' ),

        override_local_chams = subtab.esp.chams:add_checkbox( 'localplayer', 'enable chams' ),
        local_model_material = subtab.esp.chams:add_combo( 'localplayer', 'model material', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        local_model_material_overlay = subtab.esp.chams:add_combo( 'localplayer', 'model overlay', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        local_arms_material = subtab.esp.chams:add_combo( 'localplayer', 'arms material', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        local_arms_material_overlay = subtab.esp.chams:add_combo( 'localplayer', 'arms overlay', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        local_weapon_material = subtab.esp.chams:add_combo( 'localplayer', 'weapon material', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        local_weapon_material_overlay = subtab.esp.chams:add_combo( 'localplayer', 'weapon overlay', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),

        override_team_chams = subtab.esp.chams:add_checkbox( 'team', 'enable chams' ),
        team_model_material = subtab.esp.chams:add_combo( 'team', 'model material', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        team_model_material_overlay = subtab.esp.chams:add_combo( 'team', 'model overlay', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        team_arms_material = subtab.esp.chams:add_combo( 'team', 'arms material', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        team_arms_material_overlay = subtab.esp.chams:add_combo( 'team', 'arms overlay', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        team_weapon_material = subtab.esp.chams:add_combo( 'team', 'weapon material', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        team_weapon_material_overlay = subtab.esp.chams:add_combo( 'team', 'weapon overlay', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),

        override_friends_chams = subtab.esp.chams:add_checkbox( 'friends', 'enable chams' ),
        friends_model_material = subtab.esp.chams:add_combo( 'friends', 'model material', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        friends_model_material_overlay = subtab.esp.chams:add_combo( 'friends', 'model overlay', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        friends_arms_material = subtab.esp.chams:add_combo( 'friends', 'arms material', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        friends_arms_material_overlay = subtab.esp.chams:add_combo( 'friends', 'arms overlay', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        friends_weapon_material = subtab.esp.chams:add_combo( 'friends', 'weapon material', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        friends_weapon_material_overlay = subtab.esp.chams:add_combo( 'friends', 'weapon overlay', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),

        override_enemy_chams = subtab.esp.chams:add_checkbox( 'enemies', 'enable chams' ),
        enemy_model_material = subtab.esp.chams:add_combo( 'enemies', 'model material', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        enemy_model_material_overlay = subtab.esp.chams:add_combo( 'enemies', 'model overlay', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        enemy_arms_material = subtab.esp.chams:add_combo( 'enemies', 'arms material', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        enemy_arms_material_overlay = subtab.esp.chams:add_combo( 'enemies', 'arms overlay', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        enemy_weapon_material = subtab.esp.chams:add_combo( 'enemies', 'weapon material', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),
        enemy_weapon_material_overlay = subtab.esp.chams:add_combo( 'enemies', 'weapon overlay', 1, nil, 'none', 'flat', 'custom ubercharge', 'fresnel', 'bubble' ),


        override_glow = subtab.esp.glow:add_checkbox( 'custom glow', 'override glow' ),

        projectile_trajectory = subtab.esp.world:add_checkbox( 'general', 'projectile trajectory', true ),
        projectile_entities = subtab.esp.world:add_multicombo( 'general', 'predict projectiles for...', 'localplayer', 'friends', 'team', 'enemies' ),
        projectile_local_color_text = subtab.esp.world:add_text( 'general', 'localplayer color' ),
        projectile_friends_color_text = subtab.esp.world:add_text( 'general', 'friends color' ),
        projectile_team_color_text = subtab.esp.world:add_text( 'general', 'team color' ),
        projectile_enemies_color_text = subtab.esp.world:add_text( 'general', 'enemies color' ),

        projectile_camera = subtab.esp.world:add_checkbox( 'general', 'projectile land camera' )

    },
    misc = {
        menu_color = subtab.misc.general:add_text( 'general', 'menu color' ),
        antiaim_visualiser = subtab.misc.general:add_checkbox( 'general', 'antiaim lines', true ),
        btn = subtab.misc.general:add_button( 'general', 'BUTTON!!!!!!!' ),

        bomber_helper = subtab.misc.helpers:add_checkbox( 'bomber helper', 'enable', true ),
        bomber_enabled_configs = subtab.misc.helpers:add_multicombo( 'bomber helper', 'enabled configs', 'funny 2fort', 'funny spots', 'test' ),

        bomber_disable_config_builder = subtab.misc.helpers:add_checkbox( 'bomber config', 'lock config editing', true ),

        bomber_map = subtab.misc.helpers:add_text( 'bomber config', 'current map: none' ),

        bomber_sources = subtab.misc.helpers:add_combo( 'bomber config', 'map spots', 1, nil, '[+] create new' ),
        bomber_source_name = subtab.misc.helpers:add_text_area( 'bomber config', 'new name' ),

        bomber_class = subtab.misc.helpers:add_combo( 'bomber config', 'for...', 1, nil, 'scout', 'soldier', 'pyro', 'demoman', 'engineer', 'medic', 'sniper' ),
        
        bomber_position = subtab.misc.helpers:add_text( 'bomber config', 'x: 0 y: 0 z: 0' ),
        bomber_set_position = subtab.misc.helpers:add_button( 'bomber config', 'set position' ),
        bomber_teleport_position = subtab.misc.helpers:add_button( 'bomber config', 'teleport to position' ),

        bomber_yaw = subtab.misc.helpers:add_slider( 'bomber config', 'view yaw', 0, -180, 180, '°' ),
        bomber_pitch = subtab.misc.helpers:add_slider( 'bomber config', 'view pitch', 0, -89, 89, '°' ),
        bomber_demo_charge =  subtab.misc.helpers:add_slider( 'bomber config', 'charge amount', 0, 0, 100, '%' ),

        bomber_delete_spot = subtab.misc.helpers:add_button( 'bomber config', 'delete spot' ),
    }
}

local bomber_settings = { 
    map = nil,
    spots = { }
}

local bomber_visibility = { }
function bomber_visibility.lock( )
    local lock_state = not element.misc.bomber_disable_config_builder:get( )

    local has_map = bomber_settings.map ~= nil

    local spot_index = element.misc.bomber_sources:get( )
    local is_creating_new = spot_index == 1

    local _, selected_class = element.misc.bomber_class:get( )
    local is_demo = selected_class == 'demoman'

    element.misc.bomber_map:set_visible( lock_state )

    element.misc.bomber_sources:set_visible( lock_state and has_map )
    element.misc.bomber_source_name:set_visible( lock_state and has_map )

    element.misc.bomber_class:set_visible( lock_state and has_map )

    element.misc.bomber_position:set_visible( lock_state and has_map and not is_creating_new )
    element.misc.bomber_set_position:set_visible( lock_state and has_map and not is_creating_new )
    element.misc.bomber_teleport_position:set_visible( lock_state and has_map and not is_creating_new )

    element.misc.bomber_yaw:set_visible( lock_state and has_map and not is_creating_new )
    element.misc.bomber_pitch:set_visible( lock_state and has_map and not is_creating_new )
    element.misc.bomber_demo_charge:set_visible( lock_state and has_map and not is_creating_new and is_demo )

    element.misc.bomber_delete_spot:set_visible( lock_state and has_map and not is_creating_new )
end

element.misc.bomber_disable_config_builder:add_callback( bomber_visibility.lock )
bomber_visibility.lock( )

function bomber_visibility.on_new_config( self, key )
    if key == 'ENTER' then
        local prev_items = element.misc.bomber_sources:get_items( )

        local new_item = self:get( )
        table.insert( prev_items, 2, new_item )

        local new_items = prev_items

        element.misc.bomber_sources:update( new_items, 2 )

        local _, for_class = element.misc.bomber_class:get( )

        bomber_settings.spots[ new_item ] = {
            pos = vector( ),
            ang = vector( ),

            class = for_class,
            demo_chg = 0,
        }

        element.misc.bomber_position:set( 'x: 0 y: 0 z: 0' )
        element.misc.bomber_yaw:set( 0 )
        element.misc.bomber_pitch:set( 0 )
        element.misc.bomber_demo_charge:set( 0 )

        element.misc.bomber_position:set_visible( true )
        element.misc.bomber_set_position:set_visible( true )
        element.misc.bomber_teleport_position:set_visible( true )
    
        element.misc.bomber_yaw:set_visible( true )
        element.misc.bomber_pitch:set_visible( true )
        element.misc.bomber_demo_charge:set_visible( for_class == 'demoman' )

        element.misc.bomber_delete_spot:set_visible( true )
    end
end
element.misc.bomber_source_name:set_callback( bomber_visibility.on_new_config )

function bomber_visibility.on_config_switch( self )
    local idx, cfg_name = self:get( )

    local new_cfg = idx == 1

    if new_cfg then
        element.misc.bomber_position:set_visible( false )
        element.misc.bomber_set_position:set_visible( false )
        element.misc.bomber_teleport_position:set_visible( false )
        element.misc.bomber_yaw:set_visible( false )
        element.misc.bomber_pitch:set_visible( false )
        element.misc.bomber_demo_charge:set_visible( false )
        element.misc.bomber_delete_spot:set_visible( false )

        element.misc.bomber_source_name:set( '' )
        element.misc.bomber_class:set_name( 'scout' )
        element.misc.bomber_position:set( 'x: 0 y: 0 z: 0' )
        element.misc.bomber_yaw:set( 0 )
        element.misc.bomber_pitch:set( 0 )
        element.misc.bomber_demo_charge:set( 0 )
    else
        local config_data = bomber_settings.spots[ cfg_name ]

        element.misc.bomber_position:set_visible( true )
        element.misc.bomber_set_position:set_visible( true )
        element.misc.bomber_teleport_position:set_visible( true )
    
        element.misc.bomber_yaw:set_visible( true )
        element.misc.bomber_pitch:set_visible( true )
        element.misc.bomber_demo_charge:set_visible( config_data.class == 'demoman' )

        element.misc.bomber_delete_spot:set_visible( true )

        element.misc.bomber_class:set_name( config_data.class )
        element.misc.bomber_position:set( string.format( 'x: %.2f y: %.2f z: %.2f', config_data.pos:unpack( ) ) )
        element.misc.bomber_yaw:set( config_data.ang.y )
        element.misc.bomber_pitch:set( config_data.ang.x )
        element.misc.bomber_demo_charge:set( config_data.demo_chg )
    end
end
element.misc.bomber_sources:add_callback( bomber_visibility.on_config_switch )

function bomber_visibility.on_set_position( )
    local idx, cfg_name = element.misc.bomber_sources:get( )

    if idx == 1 then return end -- new cfg

    local config_data = bomber_settings.spots[ cfg_name ]
    local x, y, z = entities.GetLocalPlayer( ):GetAbsOrigin( ):Unpack( )
    config_data.pos.x = x
    config_data.pos.y = y
    config_data.pos.z = z

    element.misc.bomber_position:set( 
        ( 'x: %.2f y: %.2f z: %.2f' ):format( config_data.pos:unpack( ) )
    )
end
element.misc.bomber_set_position:add_callback( bomber_visibility.on_set_position )

function bomber_visibility.on_teleport_position( )
    local idx, cfg_name = element.misc.bomber_sources:get( )

    if idx == 1 then return end -- new cfg

    local config_data = bomber_settings.spots[ cfg_name ]
    
    client.Command( 'sv_cheats 1', true )
    client.Command( ( 'setpos %.2f %.2f %.2f' ):format( config_data.pos:unpack( ) ), true )
end
element.misc.bomber_teleport_position:add_callback( bomber_visibility.on_teleport_position )

local esp_visibility = { }

-- esp set_visible stuff
esp_visibility.groups = { 'local', 'team', 'friends', 'enemy' }
esp_visibility.fields = {
    'override_%s_chams',
    '%s_model_material',
    '%s_model_material_overlay',
    '%s_arms_material',
    '%s_arms_material_overlay',
    '%s_weapon_material',
    '%s_weapon_material_overlay',
}

esp_visibility.colors = {
    {
        color( 100, 255, 100 ),
        color( 100, 100, 255 ),
        color( 255, 100, 100 ),
        color( 255, 255, 255, 100 ),
        color( 255, 100, 100 ),
        color( 255, 255, 255, 100 )
    }, {
        color( 100, 255, 100 ),
        color( 100, 100, 255 ),
        color( 255, 100, 100 ),
        color( 255, 255, 255, 100 ),
        color( 255, 100, 100 ),
        color( 255, 255, 255, 100 )
    }, {
        color( 100, 255, 100 ),
        color( 100, 100, 255 ),
        color( 255, 100, 100 ),
        color( 255, 255, 255, 100 ),
        color( 255, 100, 100 ),
        color( 255, 255, 255, 100 )
    }, {
        color( 100, 255, 100 ),
        color( 100, 100, 255 ),
        color( 255, 100, 100 ),
        color( 255, 255, 255, 100 ),
        color( 255, 100, 100 ),
        color( 255, 255, 255, 100 )
    }
}

function esp_visibility.global( global_check, name )
    local globally_enabled = global_check:get( )

    for i = 2, #esp_visibility.fields do
        local other = true

        if i % 2 == 1 then
            local _, selected_name = element.esp[ string.format( esp_visibility.fields[ i - 1 ], name ) ]:get( )

            other = selected_name ~= 'none'
        end

        element.esp[ string.format( esp_visibility.fields[ i ], name ) ]:set_visible( globally_enabled and other )
    end
end

for i = 1, #esp_visibility.groups do
    local group_name = esp_visibility.groups[ i ]

    local global_enable_elem = element.esp[ string.format( esp_visibility.fields[ 1 ], group_name ) ]
    global_enable_elem:add_callback( bind( esp_visibility.global, global_enable_elem, group_name ) )

    -- i cba to make every one of these a separate fn so they get the global enable fn
    for j = 2, #esp_visibility.fields do
        local elem_name = string.format( esp_visibility.fields[ j ], group_name )
        local bs_elem = element.esp[ elem_name ]
        if j % 2 == 0 then
            bs_elem:add_callback( bind( esp_visibility.global, bs_elem, group_name ) )
        end

        element.esp[ elem_name .. '_color' ] = bs_elem:add_color_picker( nil, esp_visibility.colors[ i ][ j ] )

        if j <= 3 then
            element.esp[ elem_name .. '_color_invisible' ] = bs_elem:add_color_picker( nil, esp_visibility.colors[ i ][ j + 1 ] )
        end
    end

    esp_visibility.global( global_enable_elem, group_name )
end

function esp_visibility.override_global( override_chams_obj )
    local enable_chams = override_chams_obj:get( )

    for i = 1, #esp_visibility.groups do
        local override_subtab = element.esp[ esp_visibility.fields[ 1 ]:format( esp_visibility.groups[ i ] ) ]
        override_subtab:set_visible( enable_chams )
        esp_visibility.global( override_chams_obj, esp_visibility.groups[ i ] )

        if enable_chams then
            esp_visibility.global( override_subtab, esp_visibility.groups[ i ] )
        end
    end
end

element.esp.override_chams:add_callback( esp_visibility.override_global )
esp_visibility.override_global( element.esp.override_chams )


local world_visibility = { }
function world_visibility.projectile_global( _ )
    local global_enable = element.esp.projectile_trajectory:get( )

    element.esp.projectile_entities:set_visible( global_enable )
    element.esp.projectile_camera:set_visible( global_enable )

    local is_localplayer_selected = element.esp.projectile_entities:get( 'localplayer' )
    local is_friends_selected = element.esp.projectile_entities:get( 'friends' )
    local is_team_selected = element.esp.projectile_entities:get( 'team' )
    local is_enemies_selected = element.esp.projectile_entities:get( 'enemies' )

    element.esp.projectile_local_color_text:set_visible( global_enable and is_localplayer_selected )
    element.esp.projectile_friends_color_text:set_visible( global_enable and is_friends_selected )
    element.esp.projectile_team_color_text:set_visible( global_enable and is_team_selected )
    element.esp.projectile_enemies_color_text:set_visible( global_enable and is_enemies_selected )
end

element.esp.projectile_local_color = element.esp.projectile_local_color_text:add_color_picker( nil, color( 200, 200, 255 ) )
element.esp.projectile_friends_color = element.esp.projectile_friends_color_text:add_color_picker( nil, color( 200, 255, 100 ) )
element.esp.projectile_team_color = element.esp.projectile_team_color_text:add_color_picker( nil, color( 200, 200, 200, 100 ) )
element.esp.projectile_enemies_color = element.esp.projectile_enemies_color_text:add_color_picker( nil, color( 255, 180, 150 ) )

element.esp.projectile_trajectory:add_callback( world_visibility.projectile_global )
element.esp.projectile_entities:add_callback( world_visibility.projectile_global )
world_visibility.projectile_global( element.esp.projectile_trajectory )

local antiaim_subtabs = { 'generic','scout', 'soldier', 'pyro', 'demo', 'heavy', 'engineer', 'medic', 'sniper', 'spy' }
local group_order = { 'general', 'real angles', 'fakelag', 'fake angles' }

local class_textures = { }

local BASE_CLASS_TEXTURE_NAME = '%s/leaderboard_class_%s.vtf'
local classnames = { 'scout', 'soldier', 'pyro', 'demo', 'heavy', 'engineer', 'medic', 'sniper', 'spy' }

for i = 1, #classnames do
    local texture_path = BASE_CLASS_TEXTURE_NAME:format( abs_data_folder_path, classnames[ i ] )
    
    class_textures[ classnames[ i ] ] = draw.CreateTexture( texture_path )
end

for class_name, class_texture_id in pairs( class_textures ) do
    for group_idx = 1, #group_order do
        created_menu:add_group_image( 'antiaim', class_name, group_order[ group_idx ], class_texture_id )
    end
end

local function global_handle( override_obj )
    local settings = element.antiaim[ override_obj.subtab.name ]

    local globally_enabled = settings.general.override:get( )

    local yaw_mode = settings.general.mode
    local yaw_base = settings.general.yaw_base

    yaw_mode:set_visible( globally_enabled )
    yaw_base:set_visible( globally_enabled )

    local _, selected_yaw_mode = yaw_mode:get( )
    local is_legit_aa = selected_yaw_mode == 'legit'

    local real_mode = settings.real_angles.mode

    real_mode:set_visible( globally_enabled )

    local _, selected_real_mode = real_mode:get( )
    local is_real_static = selected_real_mode == 'static'
    local is_real_jitter = selected_real_mode == 'center jitter'
    local is_real_rotate_dynamic = selected_real_mode == 'rotate dynamic'

    local real_static_offset = settings.real_angles.static_offset
    local real_jitter_range = settings.real_angles.jitter_range
    local real_update_rate = settings.real_angles.update_rate
    local real_angle_1 = settings.real_angles.angle_1
    local real_angle_2 = settings.real_angles.angle_2

    real_static_offset:set_visible( globally_enabled and is_real_static )
    real_jitter_range:set_visible( globally_enabled and is_real_jitter )
    real_update_rate:set_visible( globally_enabled and is_real_rotate_dynamic )
    real_angle_1:set_visible( globally_enabled and is_real_rotate_dynamic )
    real_angle_2:set_visible( globally_enabled and is_real_rotate_dynamic )

    local fakelag_enable = settings.fakelag.fakelag
    local fakelag_amount = settings.fakelag.maximum_choke

    fakelag_enable:set_visible( globally_enabled )

    local is_fakelag_enabled = fakelag_enable:get( )
    fakelag_amount:set_visible( globally_enabled and is_fakelag_enabled )

    local fake_mode = settings.fake_angles.mode

    fake_mode:set_visible( globally_enabled and not is_legit_aa )

    local _, selected_fake_mode = fake_mode:get( )
    local is_fake_static = selected_fake_mode == 'static'
    local is_fake_jitter = selected_fake_mode == 'center jitter'
    local is_fake_rotate_dynamic = selected_fake_mode == 'rotate dynamic'

    local fake_static_offset = settings.fake_angles.static_offset
    local fake_jitter_range = settings.fake_angles.jitter_range
    local fake_update_rate = settings.fake_angles.update_rate
    local fake_angle_1 = settings.fake_angles.angle_1
    local fake_angle_2 = settings.fake_angles.angle_2

    fake_static_offset:set_visible( globally_enabled and is_fake_static and not is_legit_aa )
    fake_jitter_range:set_visible( globally_enabled and is_fake_jitter and not is_legit_aa )
    fake_update_rate:set_visible( globally_enabled and is_fake_rotate_dynamic and not is_legit_aa )
    fake_angle_1:set_visible( globally_enabled and is_fake_rotate_dynamic and not is_legit_aa )
    fake_angle_2:set_visible( globally_enabled and is_fake_rotate_dynamic and not is_legit_aa )
end

local function real_handle( override_obj )
    local settings = element.antiaim[ override_obj.subtab.name ]

    local _, selected_real_mode = override_obj:get( )
    local is_real_static = selected_real_mode == 'static'
    local is_real_jitter = selected_real_mode == 'center jitter'
    local is_real_rotate_dynamic = selected_real_mode == 'rotate dynamic'

    local real_static_offset = settings.real_angles.static_offset
    local real_jitter_range = settings.real_angles.jitter_range
    local real_update_rate = settings.real_angles.update_rate
    local real_angle_1 = settings.real_angles.angle_1
    local real_angle_2 = settings.real_angles.angle_2

    real_static_offset:set_visible( is_real_static )
    real_jitter_range:set_visible( is_real_jitter )
    real_update_rate:set_visible( is_real_rotate_dynamic )
    real_angle_1:set_visible( is_real_rotate_dynamic )
    real_angle_2:set_visible( is_real_rotate_dynamic )
end

local function fake_handle( override_obj )
    local settings = element.antiaim[ override_obj.subtab.name ]

    local yaw_mode = settings.general.mode

    local _, selected_yaw_mode = yaw_mode:get( )
    local is_legit_aa = selected_yaw_mode == 'legit'

    local fake_mode = settings.fake_angles.mode
    fake_mode:set_visible( not is_legit_aa )

    local _, selected_fake_mode = fake_mode:get( )
    local is_fake_static = selected_fake_mode == 'static'
    local is_fake_jitter = selected_fake_mode == 'center jitter'
    local is_fake_rotate_dynamic = selected_fake_mode == 'rotate dynamic'

    local fake_static_offset = settings.fake_angles.static_offset
    local fake_jitter_range = settings.fake_angles.jitter_range
    local fake_update_rate = settings.fake_angles.update_rate
    local fake_angle_1 = settings.fake_angles.angle_1
    local fake_angle_2 = settings.fake_angles.angle_2

    fake_static_offset:set_visible( is_fake_static and not is_legit_aa )
    fake_jitter_range:set_visible( is_fake_jitter and not is_legit_aa )
    fake_update_rate:set_visible( is_fake_rotate_dynamic and not is_legit_aa )
    fake_angle_1:set_visible( is_fake_rotate_dynamic and not is_legit_aa )
    fake_angle_2:set_visible( is_fake_rotate_dynamic and not is_legit_aa )
end

local function fakelag_handle( override_obj )
    local settings = element.antiaim[ override_obj.subtab.name ]

    local fakelag_amount = settings.fakelag.maximum_choke

    fakelag_amount:set_visible( override_obj:get( ) )
end

local dynamic_antiaim_settings = {
    general = {
        { type = 'combo', name = 'mode', state = 1, items = { 'legit', 'rage' }, callback = fake_handle },
        { type = 'combo', name = 'yaw base', state = 1, items = { 'viewangles', 'closest', 'closest scoped' } },
    },
    [ 'real angles' ] = {
        { type = 'combo', name = 'mode', state = 1, items = { 'static', 'center jitter', 'rotate dynamic' }, callback = real_handle },
        { type = 'slider', name = 'static offset', state = 0, min = -180, max = 180, suffix = '°' },
        { type = 'slider', name = 'jitter range', state = 0, min = -180, max = 180, suffix = '°' },
        { type = 'slider', name = 'update rate', state = 100, min = 100, max = 5000, suffix = 'ms' },
        { type = 'slider', name = 'angle #1', state = 0, min = -180, max = 180, suffix = '°' },
        { type = 'slider', name = 'angle #2', state = 0, min = -180, max = 180, suffix = '°' },
    },
    [ 'fakelag' ] = {
        { type = 'checkbox', name = 'fakelag', state = false, callback = fakelag_handle },
        { type = 'slider', name = 'maximum choke', state = 0, min = 0, max = 22, suffix = 'tick(s)' },
    },
    [ 'fake angles' ] = {
        { type = 'combo', name = 'mode', state = 1, items = { 'static', 'center jitter', 'rotate dynamic' }, callback = fake_handle },
        { type = 'slider', name = 'static offset', state = 0, min = -180, max = 180, suffix = '°', },
        { type = 'slider', name = 'jitter range', state = 0, min = -180, max = 180, suffix = '°', },
        { type = 'slider', name = 'update rate', state = 100, min = 100, max = 5000, suffix = 'ms' },
        { type = 'slider', name = 'angle #1', state = 0, min = -180, max = 180, suffix = '°' },
        { type = 'slider', name = 'angle #2', state = 0, min = -180, max = 180, suffix = '°' },
    }
}

for subtab_idx = 1, #antiaim_subtabs do
    local subtab_name = antiaim_subtabs[ subtab_idx ]
    element.antiaim[ subtab_name ] = { }
    element.antiaim[ subtab_name ][ 'general' ] = { }
    if subtab_name ~= 'generic' then
        element.antiaim[ subtab_name ][ 'general' ][ 'override' ] = subtab.antiaim[ subtab_name ]:add_checkbox( 'general', 'override generic settings', false )
    else
        element.antiaim[ subtab_name ][ 'general' ][ 'override' ] = subtab.antiaim[ subtab_name ]:add_checkbox( 'general', 'enable antiaim', false )
    end

    element.antiaim[ subtab_name ][ 'general' ][ 'override' ]:add_callback( global_handle )

    for group_name_idx = 1, #group_order do
        local group_name = group_order[ group_name_idx ]
        local cleaned_group_name = group_name:gsub( ' ', '_' )

        if group_name ~= 'general' then
            element.antiaim[ subtab_name ][ cleaned_group_name ] = { }
        end

        for set_idx = 1, #dynamic_antiaim_settings[ group_name ] do
            local setting_data = dynamic_antiaim_settings[ group_name ][ set_idx ]

            local fn_name = ( 'add_%s' ):format( setting_data.type )

            local parameters = { setting_data.name, setting_data.state }
            if setting_data.type == 'combo' then
                table.insert( parameters, 1 )
                table.insert( parameters, nil )
                for i = 1, #setting_data.items do
                    table.insert( parameters, setting_data.items[ i ] )
                end
            elseif setting_data.type == 'slider' then
                table.insert( parameters, setting_data.min )
                table.insert( parameters, setting_data.max )
                table.insert( parameters, setting_data.suffix )
            end

            local params_str = { }
            for i = 1, #parameters do
                local param = parameters[ i ]
                local param_value = tostring( param )

                local param_str = param_value

                if type( param ) == "string" then
                    param_str = ( '"%s"' ):format( param_str )
                end

                table.insert( params_str, param_str )
            end

            local cleaned_field_name = string.gsub( setting_data.name, ' ', '_' ):gsub( '#', '' )
            if debug.dynamic_antiaim then
                print( ( 'element.antiaim.%s.%s.%s = subtab.antiaim.%s.%s( self, %s, %s )' ):format( subtab_name, cleaned_group_name, cleaned_field_name, subtab_name, group_name, fn_name, table.concat( params_str, ', ' ) ) )
            end

            element.antiaim[ subtab_name ][ cleaned_group_name ][ cleaned_field_name ] = subtab.antiaim[ subtab_name ][ fn_name ]( subtab.antiaim[ subtab_name ], group_name, table.unpack( parameters ) )

            if setting_data.callback then
                element.antiaim[ subtab_name ][ cleaned_group_name ][ cleaned_field_name ]:add_callback( setting_data.callback )
            end
        end
    end

    -- call visibility check here
    global_handle( element.antiaim[ subtab_name ][ 'general' ][ 'override' ] )
end

element.misc.menu_color:add_color_picker( nil, accent_color ):set_callback( function( self )
    accent_color = self.color

    local h, s, b = color.rgb_to_hsb( accent_color )

    accent_color_light = color.hsb_to_rgb( h, s, clamp( b * 1.2, 0, 1 ) )
end )

-- lbox menu shit, i cba to do it so this stays as an extension to already existing menu
do
    -- local subtab = {
    --     rage = {
    --         main = tab.rage:add_subtab( 'main' ),
    --         secondary = tab.rage:add_subtab( 'secondary' )
    --     },
    --     legit = {
    --         main = tab.legit:add_subtab( 'main' ),
    --         trigger = tab.legit:add_subtab( 'triggerbot' )
    --     },
    --     antiaim = {
    --         global = tab.antiaim:add_subtab( 'global' ),
    --         stand = tab.antiaim:add_subtab( 'standing' ),
    --         crouch = tab.antiaim:add_subtab( 'crouching' ),
    --         air = tab.antiaim:add_subtab( 'in-air' )
    --     },
    --     esp = {
    --         lmaobox_esp = tab.esp:add_subtab( 'lbox esp' ),
    --         lmaobox_chams = tab.esp:add_subtab( 'lbox chams' ),
            
    --         esp = tab.esp:add_subtab( 'esp' ),
    --         chams = tab.esp:add_subtab( 'chams' ),
    --         glow = tab.esp:add_subtab( 'glow' ),
    --         world = tab.esp:add_subtab( 'world' ),
    --     },
    --     misc = {
    --         general = tab.misc:add_subtab( 'general' ),
    --         helpers = tab.misc:add_subtab( 'helpers' )
    --     }
    -- }

    -- local element = {
    --     rage = {
    --         enable = subtab.rage.main:add_checkbox( 'general rage settings', 'enable aimbot', nil, 'aim bot' ),
    --         fov = subtab.rage.main:add_slider( 'general rage settings', 'rage fov', 0, 0, 180, 'deg', 'aim fov', { [ 180 ] = 'unlimited', [ 0 ] = 'disabled' } ),
    --         aim_position = subtab.rage.main:add_combo( 'general rage settings', 'aim position', 1, 'aim position', 'body', 'head', 'hitscan' ),
    --         target_selection = subtab.rage.main:add_combo( 'general rage settings', 'target selection', 1, 'priority', 'lowest health', 'highest health', 'smallest distance', 'closest to crosshair' ),
    --         ignore = subtab.rage.main:add_multicombo( 'general rage settings', 'ignore if...', 'steam friend', 'deadringer', 'cloaked', 'disguised', 'taunting', 'bonked', 'vacc ubercharge' ),
    --         aim_extra = subtab.rage.main:add_multicombo( 'general rage settings', 'aim other', 'sentries', 'dispensers/teleporters', 'stickies', 'sentrybuster', 'npc' ),
    --         backtrack = subtab.rage.main:add_checkbox( 'general rage settings', 'backtrack', nil, 'backtrack' ),
    --         only_target = subtab.rage.main:add_slider( 'general rage settings', 'only target priority', 0, 0, 10, '', 'minimal priority', { [ 0 ] = 'off' } ),

    --         nospread = subtab.rage.main:add_checkbox( 'extra settings', 'disable spread', nil, 'nospread' ),
    --         norecoil = subtab.rage.main:add_checkbox( 'extra settings', 'disable recoil', nil, 'norecoil' ),
    --         minigun_spinup = subtab.rage.main:add_checkbox( 'extra settings', '[heavy] spinup', nil, 'minigun spinup' ),
    --         minigun_tapfire = subtab.rage.main:add_checkbox( 'extra settings', '[heavy] tapfire', nil, 'minigun tapfire' ),
    --         sniper_zoom_only = subtab.rage.main:add_checkbox( 'extra settings', '[sniper] zoom only', nil, 'sniper: zoomed only' ),
    --         sniper_auto_zoom = subtab.rage.main:add_checkbox( 'extra settings', '[sniper] auto zoom', nil, 'sniper: auto zoom' ),
    --         sniper_wait_for_charge = subtab.rage.main:add_checkbox( 'extra settings', '[sniper] wait charge', nil, 'wait for charge' ),
    --     },
    --     legit = {
    --         enable = subtab.legit.main:add_checkbox( 'general legit settings', 'enable legit', false ),
    --         aim_method = subtab.legit.main:add_combo( 'general legit settings', 'aim method', 1, 'aim method', 'plain', 'smooth', 'assistance' ),
    --         aim_position = subtab.legit.main:add_combo( 'general legit settings', 'aim position', 1, 'aim position', 'body', 'head', 'hitscan' ),
    --         aim_method_projectile = subtab.legit.main:add_combo( 'general legit settings', 'aim method (projectile)', 1, 'aim method (projectile)', 'plain', 'smooth', 'assistance' ),
    --         smooth_amount = subtab.legit.main:add_slider( 'general legit settings', 'smooth amount', 1, 1, 60, '', 'smooth value', { [ 1 ] = 'off' } ),
    --         smooth_algorithm = subtab.legit.main:add_combo( 'general legit settings', 'smoothing algorithm', 1, 'smooth type', 'default', 'slow end', 'constant', 'fast end' ),

    --         target_selection = subtab.rage.main:add_combo( 'target selection', 'target selection', 1, 'priority', 'lowest health', 'highest health', 'smallest distance', 'closest to crosshair' ),
    --         target_switch_delay = subtab.legit.main:add_slider( 'target selection', 'target switch delay', 0, 0, 1500, 'ms', nil, { [ 0 ] = 'off' } ),
    --         first_shot_delay = subtab.legit.main:add_slider( 'target selection', 'first shot delay', 0, 0, 500, 'ms', nil, { [ 0 ] = 'off' } ),
    --         ignore = subtab.legit.main:add_multicombo( 'target selection', 'ignore if...', 'steam friend', 'deadringer', 'cloaked', 'disguised', 'taunting', 'bonked', 'vacc ubercharge' ),
    --         aim_extra = subtab.legit.main:add_multicombo( 'target selection', 'aim other', 'sentries', 'dispensers/teleporters', 'stickies', 'sentrybuster', 'npc' ),

    --         trigger_enable = subtab.legit.trigger:add_checkbox( 'triggerbot settings', 'enable triggerbot', false, 'trigger shoot' ),
    --         trigger_aim_position = subtab.legit.trigger:add_combo( 'triggerbot settings', 'aim position', 1, 'aim position', 'body', 'head', 'hitscan' ),
    --         trigger_shoot_key = subtab.legit.trigger:add_combo( 'triggerbot settings', 'trigger key (fanta edition)', 1, 'trigger shoot key', 'MOUSE5', 'MOUSE4', 'ALT' ),
    --         trigger_melee = subtab.legit.trigger:add_checkbox( 'triggerbot settings', 'trigger melee', false, 'trigger melee' ),
    --         trigger_shoot_delay = subtab.legit.trigger:add_slider( 'triggerbot settings', 'trigger shoot delay', 0, 0, 500, 'ms', nil, { [ 0 ] = 'off' } ),
    --         trigger_sniper_through_teammates = subtab.legit.trigger:add_checkbox( 'triggerbot settings', '[sniper] shoot through teammates', false, 'sniper: shoot thru teammates' ),
    --         backtrack = subtab.legit.trigger:add_checkbox( 'triggerbot rage settings', 'backtrack', nil, 'backtrack' ),
    --     },
    --     antiaim = {
    --         global_enable = subtab.antiaim.global:add_checkbox( 'general', 'enable antiaim', true, 'anti aim' ),
    --         global_pitch_real = subtab.antiaim.global:add_combo( 'general', 'real pitch', 1, nil, 'none', 'up', 'down', 'zero', 'fake up', 'fake down' ),
    --         global_style_yaw_real = subtab.antiaim.global:add_combo( 'general', 'real yaw', 1, nil, 'static', 'jitter', 'spin' ),
    --         global_style_yaw_static = subtab.antiaim.global:add_slider( 'general', 'yaw offset', 0, -180, 180, 'deg', nil ),
    --         global_style_yaw_jitter= subtab.antiaim.global:add_slider( 'general', 'yaw range', 0, -180, 180, 'deg', nil ),
    --         global_style_yaw_spin= subtab.antiaim.global:add_slider( 'general', 'spin speed', 0, 0, 180, 'deg/t', nil ),
    --         global_style_yaw_fake = subtab.antiaim.global:add_combo( 'general', 'fake yaw', 1, nil, 'static', 'jitter', 'spin' ),

    --         duck_speed = subtab.antiaim.global:add_checkbox( 'extras', 'duck speed', true, 'duck speed' ),
    --         anti_backstab = subtab.antiaim.global:add_checkbox( 'extras', 'avoid backstab', true, 'anti backstab' ),

    --         resolver = subtab.antiaim.global:add_checkbox( 'other', 'skeet resolver', false, 'aim resolver' ),
    --         pitch_resolver = subtab.antiaim.global:add_checkbox( 'other', 'pitch resolver', false, 'aim resolver pitch (default)' ),
    --         edge_detection = subtab.antiaim.global:add_checkbox( 'other', 'edge detection', false, 'edge detection' ),

    --         fakelag = subtab.antiaim.global:add_checkbox( 'fakelag', 'enable fakelag', false, 'fake lag' ),
    --         fakelag_value = subtab.antiaim.global:add_slider( 'fakelag', 'amount', 330, 0, 330, 'ms', 'fake lag value (ms)' ),
    --         dynamic_fakelag = subtab.antiaim.global:add_checkbox( 'fakelag', 'dynamic fakelag', false, 'dynamic fake lag' ),


    --         stand_override = subtab.antiaim.stand:add_checkbox( 'general', 'override ~ stand', false ),
    --         stand_pitch_real = subtab.antiaim.stand:add_combo( 'general', 'pitch', 1, nil, 'none', 'up', 'down', 'zero', 'fake up', 'fake down' ),
    --         stand_style_yaw_real = subtab.antiaim.stand:add_combo( 'general', 'real yaw', 1, nil, 'static', 'jitter', 'spin' ),
    --         stand_style_yaw_static = subtab.antiaim.stand:add_slider( 'general', 'yaw offset', 0, -180, 180, 'deg', nil ),
    --         stand_style_yaw_jitter= subtab.antiaim.stand:add_slider( 'general', 'yaw range', 0, -180, 180, 'deg', nil ),
    --         stand_style_yaw_spin= subtab.antiaim.stand:add_slider( 'general', 'spin speed', 0, 0, 180, 'deg/t', nil ),
    --         stand_style_yaw_fake = subtab.antiaim.stand:add_combo( 'general', 'fake yaw', 1, nil, 'static', 'jitter', 'spin' ),
    --         stand_style_yaw_fake_static = subtab.antiaim.stand:add_slider( 'general', 'yaw offset', 0, -180, 180, 'deg', nil ),
    --         stand_style_yaw_fake_jitter= subtab.antiaim.stand:add_slider( 'general', 'yaw range', 0, -180, 180, 'deg', nil ),
    --         stand_style_yaw_fake_spin= subtab.antiaim.stand:add_slider( 'general', 'spin speed', 0, 0, 180, 'deg/t', nil ),

    --         crouch_override = subtab.antiaim.crouch:add_checkbox( 'general', 'override ~ crouch', false ),
    --         crouch_pitch_real = subtab.antiaim.crouch:add_combo( 'general', 'pitch', 1, nil, 'none', 'up', 'down', 'zero', 'fake up', 'fake down' ),
    --         crouch_style_yaw_real = subtab.antiaim.crouch:add_combo( 'general', 'real yaw', 1, nil, 'static', 'jitter', 'spin' ),
    --         crouch_style_yaw_static = subtab.antiaim.crouch:add_slider( 'general', 'yaw offset', 0, -180, 180, 'deg', nil ),
    --         crouch_style_yaw_jitter= subtab.antiaim.crouch:add_slider( 'general', 'yaw range', 0, -180, 180, 'deg', nil ),
    --         crouch_style_yaw_spin= subtab.antiaim.crouch:add_slider( 'general', 'spin speed', 0, 0, 180, 'deg/t', nil ),
    --         crouch_style_yaw_fake = subtab.antiaim.crouch:add_combo( 'general', 'fake yaw', 1, nil, 'static', 'jitter', 'spin' ),
    --         crouch_style_yaw_fake_static = subtab.antiaim.crouch:add_slider( 'general', 'yaw offset', 0, -180, 180, 'deg', nil ),
    --         crouch_style_yaw_fake_jitter= subtab.antiaim.crouch:add_slider( 'general', 'yaw range', 0, -180, 180, 'deg', nil ),
    --         crouch_style_yaw_fake_spin= subtab.antiaim.crouch:add_slider( 'general', 'spin speed', 0, 0, 180, 'deg/t', nil ),

    --         air_override = subtab.antiaim.air:add_checkbox( 'general', 'override ~ air', false ),
    --         air_pitch_real = subtab.antiaim.air:add_combo( 'general', 'pitch', 1, nil, 'none', 'up', 'down', 'zero', 'fake up', 'fake down' ),
    --         air_style_yaw_real = subtab.antiaim.air:add_combo( 'general', 'real yaw', 1, nil, 'static', 'jitter', 'spin' ),
    --         air_style_yaw_static = subtab.antiaim.air:add_slider( 'general', 'yaw offset', 0, -180, 180, 'deg', nil ),
    --         air_style_yaw_jitter = subtab.antiaim.air:add_slider( 'general', 'yaw range', 0, -180, 180, 'deg', nil ),
    --         air_style_yaw_spin = subtab.antiaim.air:add_slider( 'general', 'spin speed', 0, 0, 180, 'deg/t', nil ),
    --         air_style_yaw_fake = subtab.antiaim.air:add_combo( 'general', 'fake yaw', 1, nil, 'static', 'jitter', 'spin' ),
    --         air_style_yaw_fake_static = subtab.antiaim.air:add_slider( 'general', 'yaw offset', 0, -180, 180, 'deg', nil ),
    --         air_style_yaw_fake_jitter= subtab.antiaim.air:add_slider( 'general', 'yaw range', 0, -180, 180, 'deg', nil ),
    --         air_style_yaw_fake_spin= subtab.antiaim.air:add_slider( 'general', 'spin speed', 0, 0, 180, 'deg/t', nil ),
    --     },
    --     esp = {
    --         enable_lbox_esp = subtab.esp.lmaobox_esp:add_checkbox( 'general', 'enable', false, 'players' ),
    --         lbox_enemy_only = subtab.esp.lmaobox_esp:add_checkbox( 'general', 'enemy only', false, 'enemy only' ),
    --         lbox_friends = subtab.esp.lmaobox_esp:add_checkbox( 'general', 'friends', false, 'friends' ),
    --         lbox_lobby_members = subtab.esp.lmaobox_esp:add_checkbox( 'general', 'lobby', false, 'lobby members' ),
            
    --         lbox_name = subtab.esp.lmaobox_esp:add_checkbox( 'esp', 'name', false, 'name' ),
    --         lbox_steam = subtab.esp.lmaobox_esp:add_checkbox( 'esp', 'steam', false, 'steam' ),
    --         lbox_health = subtab.esp.lmaobox_esp:add_multicombo( 'esp', 'health', 'value', 'bar' ),
    --         lbox_weapon = subtab.esp.lmaobox_esp:add_combo( 'esp', 'weapon', 1, 'weapon', 'none', 'text', 'icon' ),
    --         lbox_ubercharge = subtab.esp.lmaobox_esp:add_checkbox( 'esp', 'ubercharge', false, 'ubercharge' ),
    --         lbox_distance = subtab.esp.lmaobox_esp:add_checkbox( 'esp', 'distance', false, 'distance' ),
    --         lbox_class = subtab.esp.lmaobox_esp:add_combo( 'esp', 'weapon', 1, 'class', 'none', 'text', 'icon' ),
    --         lbox_conditions = subtab.esp.lmaobox_esp:add_checkbox( 'esp', 'conditions', false, 'conditions' ),
    --         lbox_box = subtab.esp.lmaobox_esp:add_combo( 'esp', 'box', 1, 'box', 'none', 'solid', 'outlined', '3d', 'corner', 'bold', 'corner bold' ),
    --         lbox_viewangles = subtab.esp.lmaobox_esp:add_combo( 'esp', 'viewangles', 1, 'view angles', 'none', 'snipers', 'all' ),
    --         lbox_skeleton = subtab.esp.lmaobox_esp:add_combo( 'esp', 'skeleton', 1, 'skeleton', 'none', 'white', 'health', 'team' ),
    --         lbox_localplayer = subtab.esp.lmaobox_esp:add_checkbox( 'esp', 'draw on local player', false, 'local player' ),

    --         lbox_glow = subtab.esp.lmaobox_esp:add_combo( 'glow', 'glow', 1, 'glow', 'none', 'health', 'team' ),
    --         lbox_glow_style = subtab.esp.lmaobox_esp:add_combo( 'glow', 'glow style', 1, 'glow style', 'classic', 'blur glow' ),
    --         lbox_glow_mode = subtab.esp.lmaobox_esp:add_combo( 'glow', 'glow mode', 1, 'glow mode', 'solid', 'outline', 'outline-solid' ),
    --         lbox_glow_size = subtab.esp.lmaobox_esp:add_slider( 'glow', 'glow size', 0, 1, 30, '', 'glow size' ),
    --         lbox_glow_weapon = subtab.esp.lmaobox_esp:add_checkbox( 'glow', 'glow weapon', false, 'glow weapon' ),

    --         lbox_backtrack_ticks = subtab.esp.lmaobox_esp:add_checkbox( 'other', 'backtrack ticks', false ),
    --         lbox_backtrack_ticks_style = subtab.esp.lmaobox_esp:add_multicombo( 'other', 'backtrack style', 'ticks', 'chams', 'both' ),

    --         lbox_oof_arrows = subtab.esp.lmaobox_esp:add_combo( 'other', 'oof arrows', 1, 'offscreen arrows', 'none', 'all players', 'spy only' ),
    --         lbox_far_esp = subtab.esp.lmaobox_esp:add_checkbox( 'other', 'far esp', 1, 'far esp' ),
    --         lbox_hide_cloaked = subtab.esp.lmaobox_esp:add_checkbox( 'other', 'hide cloaked', 1, 'hide cloaked' ),
    --         lbox_only_draw = subtab.esp.lmaobox_esp:add_slider( 'other', 'only draw on priority', 1, 0, 10, '', 'minimal priority', { [ 0 ] = 'off' } ),
    --         lbox_aim_fov = subtab.esp.lmaobox_esp:add_checkbox( 'other', 'aim fov', false, 'aim fov range' ),
    --         lbox_aim_fov_transparency = subtab.esp.lmaobox_esp:add_slider( 'other', 'aim fov alpha', 0, 0, 100, '%', 'aim fov range transparency' ),

    --         lbox_buildings = subtab.esp.lmaobox_esp:add_checkbox( 'buildings', 'enable building esp', false, 'buildings' ),
    --         lbox_buildings_name = subtab.esp.lmaobox_esp:add_checkbox( 'buildings', 'name', false, 'buildings name' ),
    --         lbox_buildings_enemy_only = subtab.esp.lmaobox_esp:add_checkbox( 'buildings', 'enemy only', false, 'enemy only' ),
    --         lbox_buildings_health = subtab.esp.lmaobox_esp:add_multicombo( 'buildings', 'health', 'value', 'bar' ),
    --         lbox_buildings_box = subtab.esp.lmaobox_esp:add_combo( 'buildings', 'box', 1, 'box', 'none', 'solid', 'outlined', '3d', 'corner' ),
    --         lbox_buildings_glow = subtab.esp.lmaobox_esp:add_combo( 'buildings', 'glow', 1, 'glow', 'none', 'health', 'team' ),

    --         lbox_crithack_size = subtab.esp.lmaobox_esp:add_slider( 'indicators', 'crithack size', 1, 1, 9, '', 'crit hack indicator size' ),
    --         lbox_doubletap_size = subtab.esp.lmaobox_esp:add_slider( 'indicators', 'doubletap size', 1, 1, 9, '', 'double tap indicator size' ),
    --         lbox_indicator_color = subtab.esp.lmaobox_esp:add_combo( 'indicators', 'color', 1, 'text color', 'white', 'team' ),


    --         lbox_ammomedkit = subtab.esp.lmaobox_esp:add_multicombo( 'world', 'ammo & medkits', 'text', 'glow', 'both' ),
    --         lbox_dropped_ammo = subtab.esp.lmaobox_esp:add_multicombo( 'world', 'dropped ammo', 'text', 'glow', 'both' ),
    --         lbox_respawn_timers = subtab.esp.lmaobox_esp:add_checkbox( 'world', 'respawn timers', true, 'respawn timers' ),
    --         lbox_mvm_money = subtab.esp.lmaobox_esp:add_multicombo( 'world', 'mvm money', 'text', 'glow', 'both' ),
    --         lbox_halloween_items = subtab.esp.lmaobox_esp:add_multicombo( 'world', 'halloween items', 'text', 'glow', 'both' ),
    --         lbox_halloween_spells = subtab.esp.lmaobox_esp:add_multicombo( 'world', 'halloween spells', 'text', 'glow', 'both' ),
    --         lbox_halloween_pumpkin = subtab.esp.lmaobox_esp:add_multicombo( 'world', 'halloween pumpkin', 'text', 'glow', 'both' ),
    --         lbox_powerups = subtab.esp.lmaobox_esp:add_multicombo( 'world', 'power ups', 'text', 'glow', 'both' ),
    --         lbox_npc = subtab.esp.lmaobox_esp:add_multicombo( 'world', 'npc', 'text', 'glow', 'both' ),
    --         lbox_projectiles = subtab.esp.lmaobox_esp:add_multicombo( 'world', 'projectiles', 'text', 'glow', 'both' ),
    --         lbox_flag = subtab.esp.lmaobox_esp:add_multicombo( 'world', 'capture flag', 'text', 'glow', 'both' ),


    --         enable_chams_enm = subtab.esp.chams:add_checkbox( 'enemies', 'enable chams', true ),
    --         enable_chams_self = subtab.esp.chams:add_checkbox( 'self', 'enable chams', true ),
    --         enable_chams_team = subtab.esp.chams:add_checkbox( 'teammates', 'enable chams', false ),
    --         enable_chams_friends = subtab.esp.chams:add_checkbox( 'friends', 'enable chams', true ),

    --         enemy_chams_xqz = subtab.esp.chams:add_checkbox( 'enemies', 'xqz chams', true ),
    --         enemy_chams_material = subtab.esp.chams:add_combo( 'enemies', 'material', 2, '-', 'flat', 'shaded', 'fresnel', 'metallic' ),
    --         enemy_chams_material_overlay = subtab.esp.chams:add_combo( 'enemies', 'material overlay', 3, '-', 'flat', 'shaded', 'fresnel', 'metallic' ),

    --         self_chams_xqz = subtab.esp.chams:add_checkbox( 'self', 'xqz chams', false ),
    --         self_chams_material = subtab.esp.chams:add_combo( 'self', 'material', 3, '-', 'flat', 'shaded', 'fresnel', 'metallic' ),
    --         self_chams_material_overlay = subtab.esp.chams:add_combo( 'self', 'material overlay', 4, '-', 'flat', 'shaded', 'fresnel', 'metallic' ),
    --         self_chams_imaginary_feature = subtab.esp.chams:add_slider( 'self', '???', 0, 0, 10, ' bitches', nil, { [ 10 ] = 'unreal amount of bitches' } ),

    --         friends_chams_xqz = subtab.esp.chams:add_checkbox( 'friends', 'xqz chams', false ),
    --         friends_chams_material = subtab.esp.chams:add_combo( 'friends', 'material', 2, '-', 'flat', 'shaded', 'fresnel', 'metallic' ),
    --         friends_chams_material_overlay = subtab.esp.chams:add_combo( 'friends', 'material overlay', 1, '-', 'flat', 'shaded', 'fresnel', 'metallic' ),

    --         enable_glow_enm = subtab.esp.glow:add_checkbox( 'enemies', 'enable glow', false ),
    --         enable_glow_self = subtab.esp.glow:add_checkbox( 'self', 'enable glow', false ),
    --         enable_glow_team = subtab.esp.glow:add_checkbox( 'teammates', 'enable glow', false ),
    --         enable_glow_friends = subtab.esp.glow:add_checkbox( 'friends', 'enable glow', false ),
    --     },
    --     misc = {
    --         bhop = subtab.misc.general:add_checkbox( 'movement', 'bunnyhop', nil, 'bunny hop' ),
    --         autostrafe = subtab.misc.general:add_combo( 'movement', 'autostrafe', nil, 'auto strafe', 'none', 'legit', 'directional' ),
    --         rocketjump = subtab.misc.general:add_checkbox( 'movement', 'rocket jump', nil, 'rocket jump' ),
    --         duckjump = subtab.misc.general:add_checkbox( 'movement', 'duck jump', nil, 'duck jump' ),
    --         edgejump = subtab.misc.general:add_checkbox( 'movement', 'edge jump', nil, 'edge jump' ),
    --         nopush = subtab.misc.general:add_checkbox( 'movement', 'no push', nil, 'no push' ),

    --         antiafk = subtab.misc.general:add_checkbox( 'enchancers', 'anti-afk kick', nil, 'anti-afk kick' ),
    --         bypass_pure = subtab.misc.general:add_checkbox( 'enchancers', 'bypass sv_pure', nil, 'bypass sv_pure' ),
    --         bypass_smac = subtab.misc.general:add_combo( 'enchancers', 'bypass smac', nil, 'bypass smac', 'none', 'legit', 'rage' ),
    --         clean_screenshots = subtab.misc.general:add_checkbox( 'enchancers', 'clean screenshots', nil, 'clean screenshots' ),
    --     }
    -- }

    -- local test_picker = element.rage.enable:add_color_picker( 'blue team color' )

    -- local backtrack_color = element.esp.lbox_backtrack_ticks:add_color_picker( 'backtrack ticks color' )

    -- test_picker:set_callback( function( self )
    --     accent_color = self.color

    --     local h, s, b = color.rgb_to_hsb( accent_color )

    --     accent_color_light = color.hsb_to_rgb( h, s, clamp( b * 1.2, 0, 1 ) )
    -- end )


    -- element.rage.enable:add_callback( function( self ) 
    --     local global_vis = self:get( )

    --     element.rage.fov:set_visible( global_vis )
    --     element.rage.aim_position:set_visible( global_vis )
    --     element.rage.target_selection:set_visible( global_vis )
    --     element.rage.ignore:set_visible( global_vis )
    --     element.rage.nospread:set_visible( global_vis )

    --     -- set aim method to silent+ because were raging
    --     gui.SetValue( 'aim method', 'silent' )
    --     gui.SetValue( 'aim method (projectile)', 'silent' )
    --     gui.SetValue( 'projectile aimbot', 'aim' )
    --     gui.SetValue( 'melee aimbot', 'rage' )
    --     gui.SetValue( 'melee crit hack', 'force always' )

    --     gui.SetValue( 'auto backstab', 'rage' )
    --     gui.SetValue( 'auto backstab fov', 100 )
    --     gui.SetValue( 'auto sapper', 'rage' )
    --     gui.SetValue( 'auto detonate sticky', 'rage' )
    --     gui.SetValue( 'auto detonator', 1 )
    -- end )

    -- element.rage.ignore:add_callback( function( self )
    --     local checks = {
    --         [ 'steam friend' ]      = 'ignore steam friends',
    --         [ 'deadringer' ]        = 'ignore deadringer',
    --         [ 'cloaked' ]           = 'ignore cloaked',
    --         [ 'disguised' ]         = 'ignore disguised',
    --         [ 'taunting' ]          = 'ignore taunting',
    --         [ 'bonked' ]            = 'ignore bonked',
    --         [ 'vacc ubercharge' ]   = 'ignore vacc ubercharge',
    --     }

    --     for k, v in pairs( checks ) do
    --         gui.SetValue( v, self:get( k ) and 1 or 0 )
    --     end
    -- end )
end

local features = { antiaim = { }, bomber = { } }

local m_iClass_to_class = {
    'scout',
    'sniper',
    'soldier',
    'demo',
    'medic',
    'heavy',
    'pyro',
    'spy',
    'engineer'
}

local antiaim_data = {
    fake = 0,
    real = 0,
    length = 40,
    fakelagging = false,
    switch_real = false,
    switch_fake = false,
}

function features.antiaim.legit_aa( settings, cmd )
    local real_mode = settings.real_angles.mode
    local _, selected_real_mode = real_mode:get( )

    local _, yaw_base = settings.general.yaw_base:get( )

    local is_real_static = selected_real_mode == 'static'
    local is_real_jitter = selected_real_mode == 'center jitter'
    local is_real_rotate_dynamic = selected_real_mode == 'rotate dynamic'

    local view = cmd.viewangles

    local base_yaw = view.y

    if yaw_base == 'viewangles' then
        base_yaw = view.y
    elseif yaw_base == 'closest' then
        -- todo: add closest
    elseif yaw_base == 'closest scoped' then
        -- todo: add closest scoped
    end

    if clientstate.GetChokedCommands( ) == 0 then
        -- set real
        local yaw = base_yaw

        if is_real_static then
            local real_static_offset = settings.real_angles.static_offset:get( )

            yaw = yaw + real_static_offset
        elseif is_real_jitter then
            local real_jitter_range = settings.real_angles.jitter_range:get( )

            yaw = yaw + real_jitter_range * ( antiaim_data.switch_real and -1 or 1 )

            antiaim_data.switch_real = not antiaim_data.switch_real
        elseif is_real_rotate_dynamic then
            local real_update_rate = settings.real_angles.update_rate:get( )
            local real_angle_1 = settings.real_angles.angle_1:get( )
            local real_angle_2 = settings.real_angles.angle_2:get( )

            local do_first_yaw = ( ticks_to_time( globals.TickCount( ) ) * 1000 % ( real_update_rate * 2 ) ) > real_update_rate

            if do_first_yaw then
                yaw = yaw + real_angle_1
            else
                yaw = yaw + real_angle_2
            end
        end

        cmd:SetViewAngles( view.x, yaw, 0 )

        antiaim_data.real = yaw
    else
        -- set fake
        -- cmd:SetSendPacket( true )

        cmd:SetViewAngles( view.x, base_yaw, 0 )

        antiaim_data.fake = base_yaw
    end
end

function features.antiaim.rage_aa( settings, cmd )
    local real_mode = settings.real_angles.mode
    local _, selected_real_mode = real_mode:get( )

    local _, yaw_base = settings.general.yaw_base:get( )

    local is_real_static = selected_real_mode == 'static'
    local is_real_jitter = selected_real_mode == 'center jitter'
    local is_real_rotate_dynamic = selected_real_mode == 'rotate dynamic'

    local view = cmd.viewangles

    local base_yaw = view.y

    if yaw_base == 'viewangles' then
        base_yaw = view.y
    elseif yaw_base == 'closest' then
        -- todo: add closest
    elseif yaw_base == 'closest scoped' then
        -- todo: add closest scoped
    end

    if clientstate.GetChokedCommands( ) == 0 then
        -- set real
        -- cmd:SetSendPacket( false )

        local yaw = base_yaw

        if is_real_static then
            local real_static_offset = settings.real_angles.static_offset:get( )

            yaw = yaw + real_static_offset
        elseif is_real_jitter then
            local real_jitter_range = settings.real_angles.jitter_range:get( )

            yaw = yaw + real_jitter_range * ( antiaim_data.switch_real and -1 or 1 )

            antiaim_data.switch_real = not antiaim_data.switch_real
        elseif is_real_rotate_dynamic then
            local real_update_rate = settings.real_angles.update_rate:get( )
            local real_angle_1 = settings.real_angles.angle_1:get( )
            local real_angle_2 = settings.real_angles.angle_2:get( )

            local do_first_yaw = ( ticks_to_time( globals.TickCount( ) ) * 1000 % ( real_update_rate * 2 ) ) > real_update_rate

            if do_first_yaw then
                yaw = yaw + real_angle_1
            else
                yaw = yaw + real_angle_2
            end
        end

        cmd:SetViewAngles( view.x, yaw, 0 )

        antiaim_data.real = yaw
    else
        -- set fake
        -- cmd:SetSendPacket( true )
        
        local fake_mode = settings.fake_angles.mode
        local _, selected_fake_mode = fake_mode:get( )

        local is_fake_static = selected_fake_mode == 'static'
        local is_fake_jitter = selected_fake_mode == 'center jitter'
        local is_fake_rotate_dynamic = selected_fake_mode == 'rotate dynamic'

        local yaw = base_yaw

        if is_fake_static then
            local fake_static_offset = settings.fake_angles.static_offset:get( )

            yaw = yaw + fake_static_offset
        elseif is_fake_jitter then
            local fake_jitter_range = settings.fake_angles.jitter_range:get( )

            yaw = yaw + fake_jitter_range * ( antiaim_data.switch_fake and -1 or 1 )

            antiaim_data.switch_fake = not antiaim_data.switch_fake
        elseif is_fake_rotate_dynamic then
            local fake_update_rate = settings.fake_angles.update_rate:get( )
            local fake_angle_1 = settings.fake_angles.angle_1:get( )
            local fake_angle_2 = settings.fake_angles.angle_2:get( )

            local do_first_yaw = ( ticks_to_time( globals.TickCount( ) ) * 1000 % ( fake_update_rate * 2 ) ) > fake_update_rate

            if do_first_yaw then
                yaw = yaw + fake_angle_1
            else
                yaw = yaw + fake_angle_2
            end
        end

        cmd:SetViewAngles( view.x, yaw, 0 )

        antiaim_data.fake = yaw
    end
end

function features.antiaim.main( cmd )
    local lp = entities.GetLocalPlayer( )

    if not lp or not lp:IsAlive( ) then
        return
    end

    local player_class = lp:GetPropInt( 'm_iClass' )

    local settings_name = m_iClass_to_class[ player_class ]

    local enabled = element.antiaim[ settings_name ].general.override:get( )

    if not enabled then
        settings_name = 'generic'

        if not element.antiaim[ settings_name ].general.override:get( ) then
            gui.SetValue( 'Anti Aim', 0 )
            return
        end
    end

    gui.SetValue( 'Anti Aim', 1 )
    gui.SetValue( 'Anti Aim - yaw (real)', 'custom' )
    gui.SetValue( 'Anti Aim - yaw (fake)', 'custom' )
    gui.SetValue( 'Anti Aim - custom yaw (real)', 1 )
    gui.SetValue( 'Anti Aim - custom yaw (fake)', 1 )

    local settings = element.antiaim[ settings_name ]

    local fakelag_enabled = settings.fakelag.fakelag:get( )
    
    if fakelag_enabled then
        local fl_amount = settings.fakelag.maximum_choke:get( )

        if globals.TickCount( ) % 22 <= fl_amount then
            cmd:SetSendPacket( false )
        else
            cmd:SetSendPacket( true )
        end
    else
        antiaim_data.fakelagging = false
    end

    local yaw_mode = settings.general.mode

    local _, selected_yaw_mode = yaw_mode:get( )
    local is_legit_aa = selected_yaw_mode == 'legit'

    if is_legit_aa then
        features.antiaim.legit_aa( settings, cmd )
    else
        features.antiaim.rage_aa( settings, cmd )
    end
end

function features.antiaim.visualize( )
    if not element.misc.antiaim_visualiser:get( ) then return end

    local lp = entities.GetLocalPlayer( )

    if not lp or not lp:IsAlive( ) then return end

    local start = vector( lp:GetAbsOrigin( ):Unpack( ) )

    local end_pos_real = vector(
        math.cos( math.rad( antiaim_data.real ) ) * antiaim_data.length,
        math.sin( math.rad( antiaim_data.real ) ) * antiaim_data.length
    )

    local end_pos_fake = vector(
        math.cos( math.rad( antiaim_data.fake ) ) * antiaim_data.length,
        math.sin( math.rad( antiaim_data.fake ) ) * antiaim_data.length
    )

    renderer.line3d( start, start + end_pos_real, color( 255, 255, 0 ) )
    renderer.line3d( start, start + end_pos_fake, color( 255, 0, 0 ) )
end

local bomber_map_last_update = globals.RealTime( )
function features.bomber.update_map( )
    bomber_settings.map = engine.GetMapName( )
    bomber_map_last_update = globals.RealTime( )

    element.misc.bomber_map:set( string.format( 'current map: %s', bomber_settings.map ) )
end

callbacks.Register( 'CreateMove', function( cmd )
    features.antiaim.main( cmd )
    features.bomber.update_map( )
end )

callbacks.Register("Draw", function( )
    -- script features
    features.antiaim.visualize( )

    if bomber_settings.map and bomber_map_last_update + 1 < globals.RealTime( ) then
        bomber_settings.map = nil
        element.misc.bomber_map:set( 'current map: none' )
    end

    -- menu stuff
    input.update_keys( )
    created_menu:render( )
end )

callbacks.Register("Unload", function( )
    for k, v in pairs( menu_tab_icons ) do
        if debug.textures then
            print( ( '[txtrs]\tgoing to delete textures for "%s".' ):format( k ) )
        end
        v:destroy( )
    end

    for classname, texture_id in pairs( class_textures ) do
        if debug.textures then
            print( ( '[txtrs]\tgoing to delete "%s" texture id: %s.' ):format( classname, tostring( texture_id ) ) )
        end
        draw.DeleteTexture( texture_id )
        if debug.textures then
            print( ( '\t↳ job done :D' ):format( classname, tostring( texture_id ) ) )
        end
    end

    print( 'deleting zero_opacity_bg id: ' .. tostring( zero_opacity_bg ) )
    draw.DeleteTexture( zero_opacity_bg )
    print( '\n\n\nscript was unloaded\n\n\n\n\n' )
end )
