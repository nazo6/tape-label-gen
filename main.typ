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

#let file_list = (
  "./data/LCSC__WM2603060249_20260515215836.csv",
  "./data/LCSC__WM2603060300_20260515204418.csv",
  "./data/LCSC__WM2603070005_20260515215838.csv",
)

#let data = file_list.fold((), (acc, file) => {
  let raw_csv = csv(file)
  let parsed = parse_lcsc_csv(raw_csv)
  return acc + parsed
})


#let make_small_label(item) = {
  box(
    width: sub_w,
    height: sub_h,
    stroke: (thickness: 0.3pt, dash: "dashed", paint: luma(180)),
    inset: 1.0mm,
  )[
    #if item != none {
      set align(left + horizon)
      set par(leading: 0.35em)

      text(size: 7.5pt, item.at(1))
      h(1mm)
      text(size: 7pt, weight: "bold", item.at(0)) // LCSC ID
      linebreak()
      text(size: 6pt, fill: luma(80), item.at(2)) // Parameter
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
