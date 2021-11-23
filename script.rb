require "open-uri"
require "watir"
require "webdrivers"

class GameStudiosDBScrapper
  URL = "http://www.gamespain.es/explorar/"

  def run
    Watir.default_timeout = 90000

    # Load the page
    puts ("Step: Load the page")
    browser = Watir::Browser.new(:chrome)
    browser.goto(URL)

    # Click cookie popup
    puts ("Step: Click cookie popip")
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

      next_page = false

      if(browser.element(css: ".c27-explore-pagination > nav > ul > li:last-child > a").present?)
        next_page_element = browser.element(css: ".c27-explore-pagination > nav > ul > li:last-child > a")
        if(next_page_element.text == "→")
          next_page_element.click
          next_page = true
        end
      end

      break unless next_page
    end

    puts "XXXXX"
    puts results
  end


  def scrap_page(browser)
    results = []

    # Wait for page load (seconds)
    puts ("Step: Wait for page load")
    sleep(5)

    # Get elements
    puts ("Step: Wait for block visble")
    browser.element(css: ".lf-item-info-2").wait_until(timeout: 10, &:present?)

    puts ("Step: Get blocks")
    blocks = browser.elements(css: ".lf-item-info-2")

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

    telephone = nil
    email = nil
    domain = nil

    contacts = block.elements(css: ".lf-contact li")
    contacts.each do |contact|
      # puts "email XXX: #{contact.element(css: ".icon-email-heart").html}"
      if(contact.element(css: ".icon-telephone-1").exists?)
        telephone = contact.text_content.strip
      end

      if(contact.element(css: ".icon-email-heart").exists?)
        email = contact.text_content.strip
        domain = email.split("@")[1]
      end
    end

    info_card = {
      "name_1" => name_1,
      "name_2" => name_2,
      "telephone" => telephone,
      "email" => email,
      "domain" => domain
    }

    puts "----"
    puts info_card

    info_card
  end
end

GameStudiosDBScrapper.new.run
