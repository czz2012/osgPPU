/***************************************************************************
 *   Copyright (c) 2008   Art Tevs                                         *
 *                                                                         *
 *   This library is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU Lesser General Public License as        *
 *   published by the Free Software Foundation; either version 3 of        *
 *   the License, or (at your option) any later version.                   *
 *                                                                         *
 *   This library is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU Lesse General Public License for more details.                    *
 *                                                                         *
 *   The full license is in LICENSE file included with this distribution.  *
 ***************************************************************************/

#include <osgPPU/UnitText.h>

namespace osgPPU
{
    //------------------------------------------------------------------------------
    UnitText::UnitText(const UnitText& unit, const osg::CopyOp& copyop) :
        UnitInOut(unit, copyop)
    {
        mSize = unit.mSize;
    }

    //------------------------------------------------------------------------------
    UnitText::UnitText(osg::State* state) : osgPPU::UnitInOut(state)
    {
        mSize = 26.0;
    }
    //------------------------------------------------------------------------------
    UnitText::UnitText() : osgPPU::UnitInOut()
    {
        mSize = 26.0;
    }
    
    //------------------------------------------------------------------------------
    UnitText::~UnitText()
    {

    }
    
    //------------------------------------------------------------------------------
    void UnitText::init()
    {
        // initialize text
        setColor(osg::Vec4(1,1,1,1));

        // setup some defaults parameters
        setLayout(osgText::Text::LEFT_TO_RIGHT);
        setCharacterSizeMode(osgText::Text::SCREEN_COORDS);
        
        // setup stateset
        osg::StateSet* stateSet = sScreenQuad->getOrCreateStateSet();
        stateSet->setMode(GL_LIGHTING,osg::StateAttribute::OFF);
        stateSet->setMode(GL_DEPTH_TEST,osg::StateAttribute::OFF);
        stateSet->setMode(GL_BLEND,osg::StateAttribute::ON);
    
        // init inout ppu
        setOutputTextureMap(getInputTextureMap());
        UnitInOut::init();
    
        // setup projection matrix
        sProjectionMatrix = osg::Matrix::ortho2D(0,1,0,1);
        osgText::Text::setStateSet(stateSet);
    }
    
    
    //------------------------------------------------------------------------------
    void UnitText::render(int mipmapLevel)
    {
        // return if we do not get valid state
        if (!sState.getState()) return;
        
        // can only be done on valid data 
        if (mFBO.valid() && mViewport.valid())
        {
            // we take the width 640 as reference width for the size of characters
            setCharacterSize(mSize * (float(getViewport()->width()) / 640.0), 1.0);

            // compute new color, change alpha acording to the blend value
            _color.a() = getBlendValue();

            // aplly stateset
            sState.getState()->apply(sScreenQuad->getStateSet());

            // TODO: should be removed here and be handled by the stateset directly (see assignFBO() )
            sState.getState()->applyAttribute(mFBO.get());
    
            // draw the text                
            draw(sState);
        }
    }

}; // end namespace
