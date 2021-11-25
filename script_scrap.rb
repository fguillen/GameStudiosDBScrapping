require "open-uri"
require "watir"
require "webdrivers"
require "json"
require "fileutils"
require "csv"

class GameStudiosDBScrapper
  URL = "http://www.gamespain.es/explorar/"
  RESULTS_FOLDER = "#{__dir__}/results"

  def run
    Watir.default_timeout = 10
    FileUtils.mkdir_p(RESULTS_FOLDER)

    # Load the page
    puts ("Step: Load the page")
    browser = Watir::Browser.new(:chrome)
    browser.goto(URL)

    # Click cookie popup
    puts ("Step: Click cookie popup")
    browser_element = browser.element(css: "#cn-accept-cookie").wait_until(timeout: 10, &:present?)
    browser_element.click

    # Click in the Filters menu
    puts ("Step: Click in the Filters menu")
    browser_element = browser.element(css: "#c27-explore-listings > div.mobile-explore-head > a").wait_until(timeout: 10, &:present?)
    browser_element.click

    # Click in the Studios button
    puts ("Step: Click in the Studios button")
    browser_element = browser.element(css: "#select-listing-type > div.listing-cat.type-estudio.active > a").wait_until(timeout: 10, &:present?)
    browser_element.click

    results = []

    loop do
      results += scrap_page(browser)
      # break

      if next_page_button = get_next_page_button(browser)
        next_page_button.click
      else
        break
      end
    end

    File.open("#{RESULTS_FOLDER}/results.json", "w") do |f|
      f.write JSON.pretty_generate results
    end

    File.open("#{RESULTS_FOLDER}/results.csv", "w") do |f|
      f.write Utils.array_of_hashes_to_csv results
    end

    puts "End of Script :)"
  end

  def get_next_page_button(browser)
    if(browser.element(css: ".c27-explore-pagination > nav > ul > li:last-child > a").present?)
      next_page_element = browser.element(css: ".c27-explore-pagination > nav > ul > li:last-child > a")
      if(next_page_element.text == "→")
        return next_page_element
      end
    end

    nil
  end

  def scrap_page(browser)
    results = []

    # Wait for page load (seconds)
    puts ("Step: Wait for page load")
    sleep(5)

    # Get elements
    puts ("Step: Wait for block visible")
    browser.element(css: ".lf-item").wait_until(timeout: 10, &:present?)

    puts ("Step: Get blocks")
    blocks = browser.elements(css: ".lf-item")

    blocks.each do |block|
      results.push(scrap_info_block(block))
    end

    results
  end

  def scrap_info_block(block)
    # puts "XXX: #{block.class.name}"
    # puts "XXX: #{block.text}"
    # puts "XXX: #{block.html}"

    name_1 = block.element(css: "h4").text if block.element(css: "h4").present?
    name_2 = block.element(css: "h6").text if block.element(css: "h6").present?
    website = block.element(css: ".lf-head-btn a:last-child").text if block.element(css: ".lf-head-btn a:last-child").present?

    telephone = nil
    email = nil

    contacts = block.elements(css: ".lf-contact li")
    contacts.each do |contact|
      # puts "email XXX: #{contact.element(css: ".icon-email-heart").html}"
      if(contact.element(css: ".icon-telephone-1").exists?)
        telephone = contact.text_content.strip
      end

      if(contact.element(css: ".icon-email-heart").exists?)
        email = contact.text_content.strip
      end
    end

    screenshot_file = screenshot(website)

    info_card = {
      "name_1" => name_1,
      "name_2" => name_2,
      "telephone" => telephone,
      "email" => email,
      "website" => website,
      "screenshot" => screenshot_file
    }

    puts "----"
    puts info_card

    info_card
  end

  def screenshot(url)
    return "no_screenshot"
    puts "screenshot(#{url})"

    file_name = url.gsub(/\W/, "-") + ".png"
    file_path = "#{RESULTS_FOLDER}/#{file_name}"

    Screenshot.shot(url, file_path)

    file_name
  rescue Selenium::WebDriver::Error::WebDriverError, Net::ReadTimeout => e
    puts "Error trying to screenshot #{url}"
    "error"
  end
end

class Screenshot
  def self.shot(url, path)
    browser = Watir::Browser.new(:chrome)
    browser.goto(url)
    browser.screenshot.save(path)
  ensure
    browser.close
  end
end

module Utils
  def self.array_of_hashes_to_csv(array_of_hashes)
    CSV.generate do |csv|
      csv << array_of_hashes.first.keys
      array_of_hashes.each { |hash| csv << hash.values }
    end
  end
end

GameStudiosDBScrapper.new.run
