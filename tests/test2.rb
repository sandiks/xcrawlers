require_relative  '../repo'

p Repo.calc_last_page(127,20)

arr = (1..20).to_a
p h = Hash[ arr.map { |v| [ v, v*v ] } ]
p h[19]