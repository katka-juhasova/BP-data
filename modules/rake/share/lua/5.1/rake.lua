-- A Lua implementation of the Rapid Automatic Keyword Extraction
-- Released under the MIT License

local _M = {}

local function load_words(stop_words_path)
    local file = io.open(stop_words_path)
    if not file then error('could not open file '..stop_words_path) end
    local words = {}
    for line in file:lines() do
        if line:sub(1, 1) ~= '#' then 
            for word in line:gmatch('%S+') do
                words[word:lower()] = true
            end
        end
    end
    return words
end

local function generate_candidate_keywords(sentences, stop_words)
    local keywords = {}
    for s in sentences do
        local kw = {}
        for word in s:gmatch('%S+') do
            if stop_words[word] then
                if #kw > 0 then table.insert(keywords, table.concat(kw, ' ')) end
                kw = {}
            else
                table.insert(kw, word)
            end
        end
        if #kw > 0 then table.insert(keywords, table.concat(kw, ' ')) end
    end
    return keywords
end

local function calculate_word_scores(keywords)
    local frequency = {}
    local degree = {}
    local score = {}
    for _, kw in ipairs(keywords) do
        local words = {}
        for w in kw:gmatch('[^%s%d]+') do table.insert(words, w) end
        local word_degree = #words - 1
        for _, word in ipairs(words) do
            frequency[word] = (frequency[word] or 0) + 1
            degree[word] = (degree[word] or 0) + word_degree
        end
    end
    for word, f in pairs(frequency) do score[word] = (degree[word] + f) / f    end
    return score
end

local function generate_candidate_keyword_scores(keywords, word_scores)
    local scores = {}
    for _, kw in ipairs(keywords) do
        if not scores[kw] then
            local kw_score = 0
            for w in kw:gmatch('[^%s%d]+') do
                kw_score = kw_score + word_scores[w]
            end
            scores[kw] = kw_score
        end
    end
    return scores
end

--- Create a rake object
--  @param stop_words Set of stop words (i.e. a table with the words as keys), or
--         path to a file from where to load them.
--  @usage rake = require 'rake'
--         r = rake.new('SmartStoplist.txt')
--         result = r:run(text) -- returns a table mapping keywords to scores
function _M.new(stop_words)
    local rake = {}
    
    if type(stop_words) == 'string' then
        stop_words = load_words(stop_words)
    elseif type(stop_words) ~= 'table' then
        error('stop_words must be a path to a file or a set')
    end
    
    rake.stop_words = stop_words
    
    --- Run the RAKE algorithm
    --  @param text Text to extract keywords from
    --  @param return_intermediate Optional, also return intermediate results:
    --         sentences (a generator), keywords, and word scores (tables)
    --  @return Keyword scores as a table
    function rake:run(text, return_intermediate)
        if type(text) ~= 'string' then error('text must be a string') end
        text = text:lower()
        local sentences = text:gmatch('[^%p]+')
        local keywords = generate_candidate_keywords(sentences, self.stop_words)
        local word_scores = calculate_word_scores(keywords)
        local keyword_scores = generate_candidate_keyword_scores(keywords, word_scores)
        if return_intermediate then
            return sentences, keywords, word_scores, keyword_scores
        end
        return keyword_scores
    end
    return rake
end

return _M