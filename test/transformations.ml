open! Core
open! Polars

let () = Common.For_testing.install_panic_hook ~suppress_backtrace:false

(* Examples from https://pola-rs.github.io/polars-book/user-guide/transformations/joins/ *)
let%expect_test "Joins" =
  let df_customers =
    Data_frame.create_exn
      Series.
        [ int "customer_id" [ 1; 2; 3 ]; string "name" [ "Alice"; "Bob"; "Charlie" ] ]
  in
  Data_frame.print df_customers;
  [%expect
    {|
    shape: (3, 2)
    ┌─────────────┬─────────┐
    │ customer_id ┆ name    │
    │ ---         ┆ ---     │
    │ i64         ┆ str     │
    ╞═════════════╪═════════╡
    │ 1           ┆ Alice   │
    │ 2           ┆ Bob     │
    │ 3           ┆ Charlie │
    └─────────────┴─────────┘ |}];
  let df_orders =
    Data_frame.create_exn
      Series.
        [ string "order_id" [ "a"; "b"; "c" ]
        ; int "customer_id" [ 1; 2; 2 ]
        ; int "amount" [ 100; 200; 300 ]
        ]
  in
  Data_frame.print df_orders;
  [%expect
    {|
    shape: (3, 3)
    ┌──────────┬─────────────┬────────┐
    │ order_id ┆ customer_id ┆ amount │
    │ ---      ┆ ---         ┆ ---    │
    │ str      ┆ i64         ┆ i64    │
    ╞══════════╪═════════════╪════════╡
    │ a        ┆ 1           ┆ 100    │
    │ b        ┆ 2           ┆ 200    │
    │ c        ┆ 2           ┆ 300    │
    └──────────┴─────────────┴────────┘ |}];
  let df_inner_join =
    Data_frame.lazy_ df_customers
    |> Lazy_frame.join
         ~other:(Data_frame.lazy_ df_orders)
         ~on:Expr.[ col "customer_id" ]
         ~how:Inner
    |> Lazy_frame.collect_exn
  in
  Data_frame.print df_inner_join;
  [%expect
    {|
    shape: (3, 4)
    ┌─────────────┬───────┬──────────┬────────┐
    │ customer_id ┆ name  ┆ order_id ┆ amount │
    │ ---         ┆ ---   ┆ ---      ┆ ---    │
    │ i64         ┆ str   ┆ str      ┆ i64    │
    ╞═════════════╪═══════╪══════════╪════════╡
    │ 1           ┆ Alice ┆ a        ┆ 100    │
    │ 2           ┆ Bob   ┆ b        ┆ 200    │
    │ 2           ┆ Bob   ┆ c        ┆ 300    │
    └─────────────┴───────┴──────────┴────────┘ |}];
  let df_left_join =
    Data_frame.lazy_ df_customers
    |> Lazy_frame.join
         ~other:(Data_frame.lazy_ df_orders)
         ~on:Expr.[ col "customer_id" ]
         ~how:Left
    |> Lazy_frame.collect_exn
  in
  Data_frame.print df_left_join;
  [%expect
    {|
    shape: (4, 4)
    ┌─────────────┬─────────┬──────────┬────────┐
    │ customer_id ┆ name    ┆ order_id ┆ amount │
    │ ---         ┆ ---     ┆ ---      ┆ ---    │
    │ i64         ┆ str     ┆ str      ┆ i64    │
    ╞═════════════╪═════════╪══════════╪════════╡
    │ 1           ┆ Alice   ┆ a        ┆ 100    │
    │ 2           ┆ Bob     ┆ b        ┆ 200    │
    │ 2           ┆ Bob     ┆ c        ┆ 300    │
    │ 3           ┆ Charlie ┆ null     ┆ null   │
    └─────────────┴─────────┴──────────┴────────┘ |}];
  let df_outer_join =
    Data_frame.lazy_ df_customers
    |> Lazy_frame.join
         ~other:(Data_frame.lazy_ df_orders)
         ~on:Expr.[ col "customer_id" ]
         ~how:Outer
    |> Lazy_frame.collect_exn
  in
  Data_frame.print df_outer_join;
  [%expect
    {|
    shape: (4, 4)
    ┌─────────────┬─────────┬──────────┬────────┐
    │ customer_id ┆ name    ┆ order_id ┆ amount │
    │ ---         ┆ ---     ┆ ---      ┆ ---    │
    │ i64         ┆ str     ┆ str      ┆ i64    │
    ╞═════════════╪═════════╪══════════╪════════╡
    │ 1           ┆ Alice   ┆ a        ┆ 100    │
    │ 2           ┆ Bob     ┆ b        ┆ 200    │
    │ 2           ┆ Bob     ┆ c        ┆ 300    │
    │ 3           ┆ Charlie ┆ null     ┆ null   │
    └─────────────┴─────────┴──────────┴────────┘ |}];
  let df_colors =
    Data_frame.create_exn Series.[ string "color" [ "red"; "green"; "blue" ] ]
  in
  Data_frame.print df_colors;
  [%expect
    {|
    shape: (3, 1)
    ┌───────┐
    │ color │
    │ ---   │
    │ str   │
    ╞═══════╡
    │ red   │
    │ green │
    │ blue  │
    └───────┘ |}];
  let df_sizes = Data_frame.create_exn Series.[ string "size" [ "S"; "M"; "L" ] ] in
  Data_frame.print df_sizes;
  [%expect
    {|
    shape: (3, 1)
    ┌──────┐
    │ size │
    │ ---  │
    │ str  │
    ╞══════╡
    │ S    │
    │ M    │
    │ L    │
    └──────┘ |}];
  let df_cross_join =
    Data_frame.lazy_ df_colors
    |> Lazy_frame.join ~other:(Data_frame.lazy_ df_sizes) ~on:[] ~how:Cross
    |> Lazy_frame.collect_exn
  in
  Data_frame.print df_cross_join;
  [%expect
    {|
    shape: (9, 2)
    ┌───────┬──────┐
    │ color ┆ size │
    │ ---   ┆ ---  │
    │ str   ┆ str  │
    ╞═══════╪══════╡
    │ red   ┆ S    │
    │ red   ┆ M    │
    │ red   ┆ L    │
    │ green ┆ S    │
    │ green ┆ M    │
    │ green ┆ L    │
    │ blue  ┆ S    │
    │ blue  ┆ M    │
    │ blue  ┆ L    │
    └───────┴──────┘ |}];
  let df_cars =
    Data_frame.create_exn
      Series.[ string "id" [ "a"; "b"; "c" ]; string "make" [ "ford"; "toyota"; "bmw" ] ]
  in
  Data_frame.print df_cars;
  [%expect
    {|
    shape: (3, 2)
    ┌─────┬────────┐
    │ id  ┆ make   │
    │ --- ┆ ---    │
    │ str ┆ str    │
    ╞═════╪════════╡
    │ a   ┆ ford   │
    │ b   ┆ toyota │
    │ c   ┆ bmw    │
    └─────┴────────┘ |}];
  let df_repairs =
    Data_frame.create_exn Series.[ string "id" [ "c"; "c" ]; int "cost" [ 100; 200 ] ]
  in
  Data_frame.print df_repairs;
  [%expect
    {|
    shape: (2, 2)
    ┌─────┬──────┐
    │ id  ┆ cost │
    │ --- ┆ ---  │
    │ str ┆ i64  │
    ╞═════╪══════╡
    │ c   ┆ 100  │
    │ c   ┆ 200  │
    └─────┴──────┘ |}];
  let df_inner_join =
    Data_frame.lazy_ df_cars
    |> Lazy_frame.join
         ~other:(Data_frame.lazy_ df_repairs)
         ~on:Expr.[ col "id" ]
         ~how:Inner
    |> Lazy_frame.collect_exn
  in
  Data_frame.print df_inner_join;
  [%expect
    {|
    shape: (2, 3)
    ┌─────┬──────┬──────┐
    │ id  ┆ make ┆ cost │
    │ --- ┆ ---  ┆ ---  │
    │ str ┆ str  ┆ i64  │
    ╞═════╪══════╪══════╡
    │ c   ┆ bmw  ┆ 100  │
    │ c   ┆ bmw  ┆ 200  │
    └─────┴──────┴──────┘ |}];
  let df_semi_join =
    Data_frame.lazy_ df_cars
    |> Lazy_frame.join
         ~other:(Data_frame.lazy_ df_repairs)
         ~on:Expr.[ col "id" ]
         ~how:Semi
    |> Lazy_frame.collect_exn
  in
  Data_frame.print df_semi_join;
  [%expect
    {|
    shape: (1, 2)
    ┌─────┬──────┐
    │ id  ┆ make │
    │ --- ┆ ---  │
    │ str ┆ str  │
    ╞═════╪══════╡
    │ c   ┆ bmw  │
    └─────┴──────┘ |}];
  let df_anti_join =
    Data_frame.lazy_ df_cars
    |> Lazy_frame.join
         ~other:(Data_frame.lazy_ df_repairs)
         ~on:Expr.[ col "id" ]
         ~how:Anti
    |> Lazy_frame.collect_exn
  in
  Data_frame.print df_anti_join;
  [%expect
    {|
    shape: (2, 2)
    ┌─────┬────────┐
    │ id  ┆ make   │
    │ --- ┆ ---    │
    │ str ┆ str    │
    ╞═════╪════════╡
    │ a   ┆ ford   │
    │ b   ┆ toyota │
    └─────┴────────┘ |}];
  let df_trades =
    Data_frame.create_exn
      Series.
        [ datetime
            "time"
            (List.map
               [ "2020-01-01 09:01:00"
               ; "2020-01-01 09:01:00"
               ; "2020-01-01 09:03:00"
               ; "2020-01-01 09:06:00"
               ]
               ~f:Common.Naive_datetime.of_string)
        ; string "stock" [ "A"; "B"; "B"; "C" ]
        ; int "trade" [ 101; 299; 301; 500 ]
        ]
  in
  Data_frame.print df_trades;
  [%expect
    {|
    shape: (4, 3)
    ┌─────────────────────┬───────┬───────┐
    │ time                ┆ stock ┆ trade │
    │ ---                 ┆ ---   ┆ ---   │
    │ datetime[ms]        ┆ str   ┆ i64   │
    ╞═════════════════════╪═══════╪═══════╡
    │ 2020-01-01 09:01:00 ┆ A     ┆ 101   │
    │ 2020-01-01 09:01:00 ┆ B     ┆ 299   │
    │ 2020-01-01 09:03:00 ┆ B     ┆ 301   │
    │ 2020-01-01 09:06:00 ┆ C     ┆ 500   │
    └─────────────────────┴───────┴───────┘ |}];
  let df_quotes =
    Data_frame.create_exn
      Series.
        [ datetime
            "time"
            (List.map
               [ "2020-01-01 09:00:00"
               ; "2020-01-01 09:02:00"
               ; "2020-01-01 09:04:00"
               ; "2020-01-01 09:06:00"
               ]
               ~f:Common.Naive_datetime.of_string)
        ; string "stock" [ "A"; "B"; "C"; "A" ]
        ; int "trade" [ 100; 300; 501; 102 ]
        ]
  in
  Data_frame.print df_quotes;
  [%expect
    {|
    shape: (4, 3)
    ┌─────────────────────┬───────┬───────┐
    │ time                ┆ stock ┆ trade │
    │ ---                 ┆ ---   ┆ ---   │
    │ datetime[ms]        ┆ str   ┆ i64   │
    ╞═════════════════════╪═══════╪═══════╡
    │ 2020-01-01 09:00:00 ┆ A     ┆ 100   │
    │ 2020-01-01 09:02:00 ┆ B     ┆ 300   │
    │ 2020-01-01 09:04:00 ┆ C     ┆ 501   │
    │ 2020-01-01 09:06:00 ┆ A     ┆ 102   │
    └─────────────────────┴───────┴───────┘ |}];
  let df_asof_join =
    Data_frame.lazy_ df_trades
    |> Lazy_frame.join
         ~other:(Data_frame.lazy_ df_quotes)
         ~on:Expr.[ col "time" ]
         ~how:
           (As_of
              { strategy = `Backward
              ; tolerance = None
              ; left_by = Some [ "stock" ]
              ; right_by = Some [ "stock" ]
              })
    |> Lazy_frame.collect_exn
  in
  Data_frame.print df_asof_join;
  [%expect
    {|
    shape: (4, 4)
    ┌─────────────────────┬───────┬───────┬─────────────┐
    │ time                ┆ stock ┆ trade ┆ trade_right │
    │ ---                 ┆ ---   ┆ ---   ┆ ---         │
    │ datetime[ms]        ┆ str   ┆ i64   ┆ i64         │
    ╞═════════════════════╪═══════╪═══════╪═════════════╡
    │ 2020-01-01 09:01:00 ┆ A     ┆ 101   ┆ 100         │
    │ 2020-01-01 09:01:00 ┆ B     ┆ 299   ┆ null        │
    │ 2020-01-01 09:03:00 ┆ B     ┆ 301   ┆ 300         │
    │ 2020-01-01 09:06:00 ┆ C     ┆ 500   ┆ 501         │
    └─────────────────────┴───────┴───────┴─────────────┘ |}]
;;
