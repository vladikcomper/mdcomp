/* -*- Mode: C++; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Copyright (C) Flamewing 2015-2016 <flamewing.sonic@gmail.com>
 *
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

#ifndef __LIB_KOSPLUS_H
#define __LIB_KOSPLUS_H

#include <iosfwd>
#include "basic_decoder.hh"
#include "moduled_adaptor.hh"

class kosplus;
using basic_kosplus = BasicDecoder<kosplus, PadMode::DontPad>;
using moduled_kosplus = ModuledAdaptor<kosplus, 4096u, 1u>;

class kosplus : public basic_kosplus, public moduled_kosplus {
	friend basic_kosplus;
	friend moduled_kosplus;
	static bool encode(std::ostream &Dst, unsigned char const *data, size_t const Size);
public:
	using basic_kosplus::encode;
	static bool decode(std::istream &Src, std::iostream &Dst);
};

#endif // __LIB_KOSPLUS_H
