% Copyright 2011 Couchbase, Inc.
%
% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

-module(erlgeom).

-export([
    to_geom_validate/1,
    disjoint/2,
    from_geom/1,
    geosstrtree_create/0,
    geosstrtree_insert/2,
    geosstrtree_iterate/1,
    geosstrtree_query/2,
    geosstrtree_remove/2,
    get_centroid/1,
    intersection/2,
    intersects/2,
    is_valid/1,
    topology_preserve_simplify/2,
    to_geom/1,
    wkbreader_create/0,
    wkbreader_read/2,
    wkbreader_readhex/2,
    wkbwriter_create/0,
    wkbwriter_write/2,
    wkbwriter_writehex/2,
    wktreader_create/0,
    wktreader_read/2,
    wktwriter_create/0,
    wktwriter_write/2
    ]).


-on_load(init/0).


init() ->
    SoName = case code:priv_dir(?MODULE) of
    {error, bad_name} ->
        case filelib:is_dir(filename:join(["..", "priv"])) of
        true ->
            filename:join(["..", "priv", "erlgeom"]);
        false ->
            filename:join(["priv", "erlgeom"])
        end;
    Dir ->
        filename:join(Dir, "erlgeom")
    end,
    (catch erlang:load_nif(SoName, 0)).

disjoint(_Geom1, _Geom2) ->
    "NIF library not loaded".

geosstrtree_create() ->
    "NIF library not loaded".

geosstrtree_insert(_RTree, _Geom) ->
    "NIF library not loaded".

geosstrtree_iterate(_RTree) ->
    "NIF library not loaded".

geosstrtree_query(_Rtree, _Geom) ->
    "NIF library not loaded".

geosstrtree_remove(_RTree, _Geom) ->
    "NIF library not loaded".

get_centroid(_Geom1) ->
    "NIF library not loaded".

intersection(_Geom1, _Geom2) ->
    "NIF library not loaded".

intersects(_Geom1, _Geom2) ->
    "NIF library not loaded".

is_valid(_Geom1) ->
    "NIF library not loaded".

topology_preserve_simplify(_Geom1, _Tolerance) ->
    "NIF library not loaded".

wkbreader_create() ->
    "NIF library not loaded".

wkbreader_read(_WKBReader, _Wkb) ->
    "NIF library not loaded".

wkbreader_readhex(_WKBReader, _WkbHex) ->
    "NIF library not loaded".

wkbwriter_create() ->
    "NIF library not loaded".

wkbwriter_write(_WKBWriter, _Geom) ->
    "NIF library not loaded".

wkbwriter_writehex(_WKBWriter, _Geom) ->
    "NIF library not loaded".

wktreader_create() ->
    "NIF library not loaded".

wktreader_read(_WKTReader, _Wkt) ->
    "NIF library not loaded".

wktwriter_create() ->
    "NIF library not loaded".

wktwriter_write(_WKTWriter, _Geom) ->
    "NIF library not loaded".


% @doc Convert a GeoCouch geometry to a GEOS geometry, validate
% the structure of the geometry.
-spec to_geom_validate(Geom::{atom(), list()}) -> true|false.
to_geom_validate(Geom) ->
    case is_valid_geometry(Geom) of
        true -> to_geom(Geom);
        {false, Reason} -> throw(Reason)
    end.

% @doc Validate the structure of the geometry
-spec is_valid_geometry(Geom::{atom(), list()}) -> true|{false, string()}.
is_valid_geometry(Geom) ->
    case Geom of
    {'Point', Coords} ->
        case is_point(Coords) of
            true -> true;
            false -> {false, "Invalid Point"}
        end;
    {'LineString', Coords} ->
        is_linestring(Coords);
    {'Polygon', Coords} ->
        is_polygon(Coords);
    {'MultiPoint', Coords} ->
        case all(fun(Coord) -> is_point(Coord) end, Coords) of
        true ->
            true;
        false ->
            {false, "Not every position of the MultiPoint is a valid Point"}
        end;
    {'MultiLineString', Coords} ->
        is_polygon(Coords);
    {'MultiPolygon', Coords} ->
        case all(fun(Coord) -> is_polygon(Coord) end, Coords) of
        true ->
            true;
        false ->
            {false, "Not every Polygon is a valid one"}
        end;
    {'GeometryCollection', Coords} ->
        case all(fun(Coord) -> is_valid_geometry(Coord) end, Coords) of
        true ->
            true;
        false ->
            {false, "Not every Geometry is a valid one"}
        end;
    {GeomType, _} when is_atom(GeomType) ->
        {false, "Invalid geometry type (" ++ atom_to_list(GeomType) ++ ")"};
    _ ->
        {false, "Invalid geometry"}
    end.

-spec is_polygon(Coords::[[[number()]]]) -> true|false.
is_polygon(Coords) ->
  case all(fun(Coord) -> is_linestring(Coord) end, Coords) of
  true ->
      true;
  false ->
      {false, "Not every LineString is a valid one"}
  end.

-spec is_linestring(Coords::[[number()]]) -> true|false.
is_linestring(Coords) when length(Coords) =< 1 ->
    {false, "LineString must have more than one position"};
is_linestring(Coords) ->
    case all(fun(Coord) -> is_point(Coord) end, Coords) of
    true ->
        true;
    false ->
        {false, "Not every position of the LineString is a valid point"}
    end.

% @doc Input is a point
-spec is_point(Point::[number()]) -> true|false.
is_point([]) ->
    true;
is_point([X, Y]) when is_number(X) andalso is_number(Y) ->
    true;
is_point(_) ->
    false.

% @doc Works like lists:all, except that not only "false", but all values
% count as false. An empty list returns false. Returns also false if it
% isn't a valid list
all(_Fun, []) ->
    false;
all(Fun, List) when is_list(List) ->
    all2(Fun, List);
all(_Fun, _NotAList) ->
    false.
all2(_Fun, []) ->
    true;
all2(Fun, [H|T]) ->
    case Fun(H) of
    true ->
        all2(Fun, T);
    _ ->
        false
    end.

% @doc Convert a GeoCouch geometry to a GEOS geometry
to_geom(_Geom) ->
    "NIF library not loaded".

% @doc Convert a GEOS geometry to a GeoCouch geometry
from_geom(_Geom) ->
    "NIF library not loaded".
