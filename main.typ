#import "./lcsc_import.typ": *

// Layout: https://www.a-one.co.jp/product/search/detail.php?id=28844

#let label_w = 83.8mm
#let label_h = 42.3mm
#let gap_x = 3.8mm
#let gap_y = 0mm

#let sub_cols = 2
#let sub_rows = 5
#let sub_w = label_w / sub_cols
#let sub_h = label_h / sub_rows
#let total_w = label_w * 2 + gap_x
#let total_h = label_h * 5


#set page(
  width: 210mm,
  height: 297mm,
  margin: (
    left: 19.3mm,
    top: 21.5mm,
    right: 19.3mm,
    bottom: 21.7mm,
  ),
  background: place(top + left)[
    #box(width: 210mm, height: 297mm, stroke: 1pt + red)

    #place(dx: 19.3mm, dy: 21.5mm)[
      #box(width: total_w, height: total_h, stroke: 1.5pt + blue)
    ]
  ],
)
#set text(font: ("Noto Sans CJK JP", "MS PGothic", "BIZ UDPGothic"), size: 7pt)

#let data = (
  read("./data/index.txt")
    .trim("\n")
    .split("\n")
    .fold((), (acc, file) => {
      let raw_csv = csv("./data/" + file)
      let parsed = parse_lcsc_csv(raw_csv)
      return acc + parsed
    })
)

#let truncate_lines(s, width, max_lines) = {
  let words = s.replace(regex("\\s+"), " ").trim().split().filter(word => word != "")

  let lines = ()
  let current = ()
  let truncated = false

  for word in words {
    let candidate = (current + (word,)).join(" ")

    if measure(text(candidate)).width <= width {
      current.push(word)
    } else {
      // 現在の行に単語があれば、次の行へ送る。
      if current.len() > 0 {
        // これ以上行を増やせない場合は省略する。
        if lines.len() + 1 >= max_lines {
          truncated = true
          break
        }

        lines.push(current)
        current = ()
      }

      // 単語自体が幅を超える場合も、途中では切らない。
      if measure(text(word)).width > width {
        truncated = true
        break
      }

      current.push(word)
    }
  }

  lines.push(current)

  if truncated {
    let last = lines.pop()

    // … が収まるまで、末尾の単語を丸ごと削る。
    while (
      last.len() > 0 and measure(text(last.join(" ") + "…")).width > width
    ) {
      let _ = last.pop()
    }

    lines.push((last.join(" ") + "…",))
  }

  lines.map(words => box(text(words.join(" ")))).join(linebreak())
}

#let make_small_label(item) = {
  box(
    width: sub_w,
    height: sub_h,
    stroke: (
      thickness: 0.3pt,
      dash: "dashed",
      paint: luma(180),
    ),
    inset: 1.0mm,
  )[
    #if item != none {
      set align(left + horizon)
      set par(leading: 0.35em, justify: false)

      layout(size => {
        // size.width は inset を除いた内側の幅。
        let w = size.width

        let mpn = box(text(size: 7.5pt, item.at(1)))
        let lcsc = box(text(
          size: 7pt,
          weight: "bold",
          item.at(0),
        ))

        let same_line = (
          measure(mpn).width + 1mm + measure(lcsc).width <= w
        )

        let header = if same_line {
          [#mpn#h(1mm)#lcsc]
        } else {
          [#mpn#linebreak()#lcsc]
        }

        let parameter = {
          set text(
            size: 6pt,
            fill: luma(80),
            hyphenate: false,
          )

          truncate_lines(
            item.at(2),
            w,
            if same_line { 2 } else { 1 },
          )
        }

        [#header#linebreak()#parameter]
      })
    }
  ]
}


#let make_big_label(items) = {
  grid(
    columns: (sub_w,) * sub_cols,
    rows: (sub_h,) * sub_rows,
    ..items.map(make_small_label)
  )
}

#let process_data(data) = {
  let sub_total = sub_cols * sub_rows
  let big_labels = ()
  let i = 0

  while i < data.len() {
    let current_chunk = data.slice(i, calc.min(i + sub_total, data.len()))
    while current_chunk.len() < sub_total {
      current_chunk.push(none)
    }
    big_labels.push(make_big_label(current_chunk))
    i += sub_total
  }
  return big_labels
}

#grid(
  columns: (label_w, label_w),
  column-gutter: gap_x,
  row-gutter: gap_y,
  ..process_data(data)
)
