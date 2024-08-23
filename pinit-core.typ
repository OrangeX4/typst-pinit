// -----------------------------------------------
// Code from https://github.com/ntjess/typst-drafting
// -----------------------------------------------
#let _run-func-on-first-loc(func, label-name: "loc-tracker") = {
  // Some placements are determined by locations relative to a fixed point. However, typst
  // will automatically re-evaluate that computation several times, since the usage
  // of that computation will change where an element is placed (and therefore update its
  // location, and so on). Get around this with a state that only checks for the first
  // update, then ignores all subsequent updates
  let lbl = label(label-name)
  [#metadata(label-name)#lbl]
  context {
    let use-loc = query(selector(lbl).before(here())).last().location()
    func(use-loc)
  }
}

/// Place content at a specific location on the page relative to the top left corner
/// of the page, regardless of margins, current container, etc.
///
/// > This function comes from [typst-drafting](https://github.com/ntjess/typst-drafting), Thanks to [ntjess]((https://github.com/ntjess/).
///
/// - `dx`: [`length`] &mdash; Length in the x-axis relative to the left edge of the page.
/// - `dy`: [`length`] &mdash; Length in the y-axis relative to the top edge of the page.
/// - `body`: [`content`] &mdash; The content you want to place.
#let absolute-place(dx: 0em, dy: 0em, body) = {
  _run-func-on-first-loc(loc => {
    let pos = loc.position()
    place(dx: -pos.x + dx, dy: -pos.y + dy, body)
  })
}

// -----------------------------------------------
// Core
// -----------------------------------------------

#let _pin-label(loc, name) = label("page-" + str(loc.position().page) + ":" + repr(name))

/// Pinning a pin in text, the pin is supposed to be unique in one page.
///
/// - `name`: [`integer` or `string` or `any`] &mdash; Name of pin, which can be any types with unique `repr()` return value, such as integer and string.
#let pin(name) = {
  _run-func-on-first-loc(loc => {
    [#metadata("pin-tracker")#_pin-label(loc, name)]
  })
}

/// Query positions of pins in the same page, then call the callback function `func`.
///
/// - `pins`: [`pin` or `array`] &mdash; Names of pins you want to query. It is supposed to be a pin, or an array of pins.
/// - `func`: [`(positions) => { .. }`] &mdash; A callback function accepting an array of positions (or a single position) as a parameter. Each position is a dictionary like `(page: 1, x: 319.97pt, y: 86.66pt)`. You can use the `absolute-place` function in this callback function to display something around the pins.
#let pinit(pins, func) = {
  let is-single-arg = false
  if type(pins) != array {
    is-single-arg = true
    pins = (pins,)
  }
  _run-func-on-first-loc(loc => {
    let positions = ()
    for pin-name in pins {
      let elems = query(
        selector(_pin-label(loc, pin-name)),
      )
      if elems == () {
        return
      }
      positions.push(elems.at(0).location().position())
    }
    if (is-single-arg) {
      func(positions.at(0))
    } else {
      func(positions)
    }
  })
}

/// Place content at a specific location on the page relative to the pin.
///
/// - `pin-name`: [`pin`] &mdash; Name of the pin to which you want to locate.
/// - `body`: [`content`] &mdash; The content you want to place.
/// - `dx`: [`length`] &mdash; Offset X relative to the pin.
/// - `dy`: [`length`] &mdash; Offset Y relative to the pin.
#let pinit-place(
  pin-name,
  body,
  dx: 0pt,
  dy: 0pt,
) = {
  pinit(
    pin-name,
    pos => {
      absolute-place(dx: pos.x + dx, dy: pos.y + dy, body)
    },
  )
}

