#let extract_rlc_params(desc, package) = {
  if desc == none or desc == "" { return package }

  let tokens = desc.split(" ")
  let extracted = ()

  let target_units = ("Ω", "F", "H", "V", "W", "A", "%")

  for token in tokens {
    if target_units.any(u => token.contains(u)) {
      if token.contains("RoHS") { continue }
      extracted.push(token)
    }
  }

  // 最後にパッケージ情報（0603など）を付与
  if package != none and package != "" {
    // すでにパッケージ情報が含まれていない場合のみ追加
    if not extracted.any(e => e.contains(package)) {
      extracted.push(package)
    }
  }

  return extracted.join(" ")
}

#let parse_lcsc_csv(raw_data) = {
  let headers = raw_data.at(0)

  let find_col(keywords) = headers.position(h => keywords.any(k => lower(h).contains(lower(k))))

  let idx_lcsc = find_col(("lcsc", "商品番号"))
  let idx_mpn = find_col(("mfr.part", "manufacture part", "メーカー型番"))
  let idx_desc = find_col(("description", "詳細", "説明"))
  let idx_pkg = find_col(("package", "パッケージ", "footprint"))
  let idx_qty = find_col(("qty", "quantity", "数量", "order qty."))

  let formatted_data = ()

  for row in raw_data.slice(1) {
    if row.len() == 0 or row.at(0) == "" { continue }

    let lcsc = if idx_lcsc != none { row.at(idx_lcsc) } else { "" }
    let mpn = if idx_mpn != none { row.at(idx_mpn) } else { "" }
    let desc = if idx_desc != none { row.at(idx_desc) } else { "" }
    let pkg = if idx_pkg != none { row.at(idx_pkg) } else { "" }

    let params = extract_rlc_params(desc, pkg)

    formatted_data.push((lcsc, mpn, params))

    if idx_qty != none {
      let qty = int(row.at(idx_qty))
      if qty >= 50 {
        formatted_data.push((lcsc, mpn, params))
      }
    }
  }

  return formatted_data
}
