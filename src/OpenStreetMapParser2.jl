module OpenStreetMapParser2
using LightXML


struct Node
    x::Float64
    y::Float64
    id::String
end

struct Tag
    key::String
    val::String
end

mutable struct Way
    id::String
    visible::Bool
    version::Int
    changeset::String
    timestamp::String
    user::String
    uid::String
    nodes::Array{Node}
    tags::Array{Tag}
    Way() = new()
end

mutable struct Relation
    id::String
    visible::Bool
    version::Int
    changeset::String
    timestamp::String
    user::String
    uid::String
    members::Array{Any}
    tags::Array{Tag}
    Relation() = new()
end

function open_file(filepath::String)
	xdoc = parse_file(filepath)
	xroot = root(xdoc)  # an instance of XMLElement
	return xroot
end

function parse_nodes(xroot::XMLElement)
    node_arr = Node[]
    for node in xroot["node"]
        id = attribute(node, "id")
        lat = parse(Float64, attribute(node, "lat"))
        lon = parse(Float64, attribute(node, "lon"))
        push!(node_arr, Node(lat, lon, id))
    end
    return node_arr
end

function find_node(id::String, node_arr::Array{Node})
    return node_arr[findfirst(x -> x.id == id, node_arr)]
end
function find_way(id::String, way_arr::Array{Way})
	try
    	return way_arr[findfirst(x -> x.id == id, way_arr)]
    catch
    	return false
    end
end
function parse_ways(xroot::XMLElement)
    way_arr = Way[]
    node_arr = parse_nodes(xroot)
    for way in xroot["way"]
        cur_way = Way()
        cur_way.id = attribute(way, "id")
        cur_way.visible = lowercase(attribute(way, "visible")) == "true"
        cur_way.version = parse(Int, attribute(way, "version"))
        cur_way.changeset = attribute(way, "changeset")
        cur_way.timestamp = attribute(way, "timestamp")
        cur_way.user = attribute(way, "user")
        cur_way.uid = attribute(way, "uid")
        cur_way.nodes = []
        for node in way["nd"]
            push!(cur_way.nodes, find_node(attribute(node, "ref"), node_arr))
        end
        cur_way.tags = []
        for tag in way["tag"]
            push!(cur_way.tags, Tag(attribute(tag, "k"), attribute(tag, "v")))
        end
        push!(way_arr, cur_way)
    end
    return way_arr
end

function parse_relations(xroot::XMLElement, way_arr::Array{Way}, node_arr::Array{Node})
	rel_arr = []
    for rel in xroot["relation"]
        cur_rel = Relation()
        cur_rel.id = attribute(rel, "id")
        cur_rel.visible = lowercase(attribute(rel, "visible")) == "true"
        cur_rel.version = parse(Int, attribute(rel, "version"))
        cur_rel.changeset = attribute(rel, "changeset")
        cur_rel.timestamp = attribute(rel, "timestamp")
        cur_rel.user = attribute(rel, "user")
        cur_rel.uid = attribute(rel, "uid")
        cur_rel.members = []
        for member in rel["member"]
        	ref = attribute(member, "ref")
        	if attribute(member, "type") == "node"
            	push!(cur_rel.members, find_node(ref, node_arr))
            elseif attribute(member, "type") == "way"
            	try
            		temp_way = find_way(ref, way_arr)
            		if temp_way != false
            			push!(cur_rel.members, temp_way)
            		end
            	catch
            		continue
            	end
            end
        end
        cur_rel.tags = []
        for tag in rel["tag"]
            push!(cur_rel.tags, Tag(attribute(tag, "k"), attribute(tag, "v")))
        end
        push!(rel_arr, cur_rel)
    end
    return rel_arr
end

export open_file, parse_nodes, parse_ways, parse_relations, Node, Tag, Way

end
