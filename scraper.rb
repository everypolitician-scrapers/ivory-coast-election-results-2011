#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'cgi'
require 'json'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def gender_from(name)
  return 'female' if name.start_with? 'Mme'
  return 'male' if name.start_with? 'Mr.'
  raise "Unknown gender for #{name}"
end

def scrape_list(url)
  noko = noko_for(url)
  saved_count = 0
  noko.css('a[href*="departement"]').each do |departement|
    results = departement.xpath('./following::table[1]')
    winner_count = results.css('td.tdJaune').text.gsub(/[[:space:]]+/,' ').split(':').last.to_i
    # puts "#{departement.text}: #{winner_count}"

    winners = results.css('.E_Titre table img[src*="depute_elu.png"]')
    raise "Should have #{winner_count} winner(s), only got #{winners.count}" unless winner_count = winners.count

    area = departement.text
    area_id = departement.attr('href').match(/R=(\d+)&D=(\d+)/).captures.join("-")
    winners.each do |winner|
      tr = winner.parent.parent
      tds = tr.css('td')

      name = tds[4].css('strong').first.text.strip
      data = { 
        name: name,
        gender: gender_from(name),
        occupation: tds[4].css('.candidatFonction').text.strip,
        party: tds[1].text.strip,
        image: tds[3].css('img/@src').text,
        area: area,
        area_id: area_id,
        term: '2.2',
        source: @BASE,
      }
      saved_count += 1
      ScraperWiki.save_sqlite([:name, :term], data)
    end
  end
  puts "Added #{saved_count} winners"
end

@BASE = 'http://forums.abidjan.net/elections/legislatives/2011/resultats/resultats.asp'
# ASP madness, so just use locally saved copy of fully rendered page
scrape_list('resultats.asp')
