/*   Bluebird Library - High performance CPUs and GPUs computing library.
*    
*    Copyright (C) 2012-2013 Orange Owl Solutions.  
*
*    This file is part of Bluebird Library.
*    Bluebird Library is free software: you can redistribute it and/or modify
*    it under the terms of the Lesser GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*
*    Bluebird Library is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    Lesser GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with Bluebird Library.  If not, see <http://www.gnu.org/licenses/>.
*
*
*    For any request, question or bug reporting please visit http://www.orangeowlsolutions.com/
*    or send an e-mail to: info@orangeowlsolutions.com
*
*
*/


#ifndef __DGLOBALS_CUH__
#define __DGLOBALS_CUH__

namespace BB {
	
	/*! \brief Block size for the kernel calls. */
	dim3 dimBlock(BLOCKSIZE);

	/*! \brief Object handling CUDA streams. */
	DStreams streams[MAX_NUM_GPUs];

	/*! \brief Object handling CUDA multi-GPU. */
	P2P p2p; 

	/*! \brief SpanClass object. */
	const SpanClass Span;

	extern	int iDivUp(const int a, const int b) { return (a % b != 0) ? (a / b + 1) : (a / b); }
}

#endif