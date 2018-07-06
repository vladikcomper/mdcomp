/* -*- Mode: C++; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Copyright (C) Clownacy 2016
 * Copyright (C) Flamewing 2016 <flamewing.sonic@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef __LIB_ROCKET_H
#define __LIB_ROCKET_H

#include <iosfwd>
#include "basic_decoder.hh"
#include "moduled_adaptor.hh"

class rocket;
using basic_rocket = BasicDecoder<rocket, PadMode::DontPad>;
using moduled_rocket = ModuledAdaptor<rocket, 4096u, 1u>;

class rocket : public basic_rocket, public moduled_rocket {
	friend basic_rocket;
	friend moduled_rocket;
	static bool encode(std::ostream &Dst, unsigned char const *data, size_t const Size);
public:
	using basic_rocket::encode;
	static bool decode(std::istream &Src, std::iostream &Dst);
};

#endif // __LIB_ROCKET_H
