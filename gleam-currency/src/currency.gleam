import gleam/int
import gleam/io
import gleam/result
import gleam/string_tree

import wisp.{type Request, type Response}

pub fn main() {
  let port = 8080
  io.println("Currency service started on port " <> int.to_string(port))
}
