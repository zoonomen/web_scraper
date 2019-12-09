require 'date'
require 'fileutils'

class Downloader

  def initialize(year = nil, month = nil, day = nil)
    unless year and month and day
      today = DateTime.now
      year = today.year
      month = today.month
      day = today.day
    end

    @file_path = "./pages/#{year}/#{month}/#{day}/"
    @base_url = 'http://zoonomen.net/'
  end

  def new_toc
    download_to_file(@base_url + 'avtax/toc.html', 'toc.html')
  end

  def taxa_data(path, force = false)
    check_avtax_folder
    find_or_create_data('avtax/', path, force)
  end


  def check_avtax_folder
    @_avtax_folder ||= create_folder('avtax/')
  end


  def find_or_create_data(folder, file, force)
    full_file_path = @file_path + folder + file

    if force or !File.exist?(full_file_path)
      full_url = @base_url + folder + file
      download_to_file(full_url, full_file_path)
    end

    open(full_file_path)
  end

  def create_folder(folder)
    FileUtils.mkdir_p(@file_path + folder)
  end

  def download_to_file(url, file_path)
    begin
      open(file_path, 'wb') do |file|
        open(url) do |page|
          file.write(page.read)
        end
      end
    rescue
      puts "UNABLE TO DOWNLOAD #{url}"
    end
  end

  def cit_data(path, force = false)
    check_cit_folder
    find_or_create_data('cit/', path, force)
  end

  def check_cit_folder
    @_cit_folder ||= create_folder('cit/')
  end

  def author_data(path, force = false)
    check_author_folder
    find_or_create_data('bio/', path, force)
  end

  def check_author_folder
    @_author_folder ||= create_folder('bio/')
  end
end
