
def calc_page(count)
  pc = count/20 + 1
end

def smid_from_url(url)
  url.split('/').last.split('.').first.to_i
end

def forum_name_from_url(url)
  url.split('/')[2]
end

def convert_to_flat(url)
  url.sub('.1','.flat.')
end
