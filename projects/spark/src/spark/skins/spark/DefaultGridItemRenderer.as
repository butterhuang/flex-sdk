package spark.skins.spark
{
    
import flash.display.DisplayObject;
import flash.events.Event;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.text.TextFieldAutoSize;

import mx.core.IUITextField;
import mx.core.LayoutElementUIComponentUtils;
import mx.core.UIComponent;
import mx.core.UITextField;
import mx.core.mx_internal;
import mx.events.FlexEvent;

import spark.components.Grid;
import spark.components.IGridItemRenderer;
import spark.components.supportClasses.GridColumn;

use namespace mx_internal;

//--------------------------------------
//  Events
//--------------------------------------

/**
 *  Dispatched when the bindable <code>data</code> property changes.
 *
 *  @eventType mx.events.FlexEvent.DATA_CHANGE
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
[Event(name="dataChange", type="mx.events.FlexEvent")]

/**
 *  TBD
 */
public class DefaultGridItemRenderer extends UIComponent implements IGridItemRenderer
{
    public function DefaultGridItemRenderer()
    {
        super();
    }
    
    /**
     *  Padding for the entire renderer.  Not to be confused with the UITextField 
     *  TEXT_WIDTH,HEIGHT_PADDING values which must be added to its textWidth,Height
     *  to prevent clipping/wrapping.
     */
    private static const WIDTH_PADDING:Number = 15;
    private static const HEIGHT_PADDING:Number = 7;
    
    /** 
     *  Used to flag a lineBreak style change for commitProperties().   See styleChanged().
     */
    private var lineBreakStyleChanged:Boolean = false;    
    
    //--------------------------------------------------------------------------
    //
    //  Properties 
    //
    //--------------------------------------------------------------------------
    
    private function dispatchChangeEvent(type:String):void
    {
        if (hasEventListener(type))
            dispatchEvent(new Event(type));
    }
    
    //----------------------------------
    //  column
    //----------------------------------
    
    private var _column:GridColumn = null;
    
    [Bindable("columnChanged")]
    
    /**
     *  @inheritDoc
     * 
     *  <p>The Grid's <code>updateDisplayList()</code> method sets this property 
     *  before calling <code>preprare()</code></p>. 
     *  
     *  @default null
     */
    public function get column():GridColumn
    {
        return _column;
    }
    
    /**
     *  @private
     */
    public function set column(value:GridColumn):void
    {
        if (_column == value)
            return;
        
        _column = value;
        dispatchChangeEvent("columnChanged");
    }
    
    //----------------------------------
    //  data
    //----------------------------------
    
    private var _data:Object = null;
    
    [Bindable("dataChange")]  // compatible with FlexEvent.DATA_CHANGE
    
    /**
     *  The value of the dataProvider "item" for this row, i.e. <code>dataProvider.getItemAt(itemIndex)</code>.
     *  Item renderers often bind visual element attributes to data properties.  Note 
     *  that, despite its name, this property does not depend on the column's "dataField". 
     *  
     *  @default null
     */
    public function get data():Object
    {
        return _data;
    }
    
    /**
     *  @private
     */
    public function set data(value:Object):void
    {
        if (_data == value)
            return;
        
        _data = value;

        const eventType:String = "dataChange"; 
        if (hasEventListener(eventType))
            dispatchEvent(new FlexEvent(eventType));        
    }
    
    //----------------------------------
    //  hovered
    //----------------------------------
    /**
     *  @private
     *  storage for the selected property 
     */    
    private var _hovered:Boolean = false;
    
    /**
     *  Set to <code>true</code> when the mouse is hovered over the item renderer.
     *
     *  @default false
     */    
    public function get hovered():Boolean
    {
        return _hovered;
    }
    
    /**
     *  @private
     */    
    public function set hovered(value:Boolean):void
    {
        _hovered = value;
    }
    
    //----------------------------------
    //  rowIndex
    //----------------------------------
    
    private var _rowIndex:int = -1;
    
    [Bindable("rowIndexChanged")]
    
    /**
     *  @inheritDoc
     * 
     *  <p>The Grid's <code>updateDisplayList()</code> method sets this property 
     *  before calling <code>prepare()</code></p>.   
     * 
     *  @default -1
     */    
    public function get rowIndex():int
    {
        return _rowIndex;
    }
    
    /**
     *  @private
     */    
    public function set rowIndex(value:int):void
    {
        if (_rowIndex == value)
            return;
        
        _rowIndex = value;
        dispatchChangeEvent("rowIndexChanged");        
    }
    
    //----------------------------------
    //  showsCaret
    //----------------------------------
    
    private var _showsCaret:Boolean = false;
    
    [Bindable("showsCaretChanged")]    
    
    /**
     *  @inheritDoc
     * 
     *  <p>The Grid's <code>updateDisplayList()</code> method sets this property 
     *  before calling <code>preprare()</code></p>.   
     * 
     *  @default false
     */    
    public function get showsCaret():Boolean
    {
        return _showsCaret;
    }
    
    /**
     *  @private
     */    
    public function set showsCaret(value:Boolean):void
    {
        if (_showsCaret == value)
            return;
        
        _showsCaret = value;
        dispatchChangeEvent("labelDisplayChanged");           
    }
    
    //----------------------------------
    //  selected
    //----------------------------------
    
    private var _selected:Boolean = false;
    
    [Bindable("selectedChanged")]    
    
    /**
     *  @inheritDoc
     * 
     *  <p>The Grid's <code>updateDisplayList()</code> method sets this property 
     *  before calling <code>preprare()</code></p>.   
     * 
     *  @default false
     */    
    public function get selected():Boolean
    {
        return _selected;
    }
    
    /**
     *  @private
     */    
    public function set selected(value:Boolean):void
    {
        if (_selected == value)
            return;
        
        _selected = value;
        dispatchChangeEvent("selectedChanged");        
    }
    
    //----------------------------------
    //  singleLine (private)
    //----------------------------------

    private var _singleLine:Boolean = false;
    
    /**
     *  @private
     *  If true, then the labelDisplay is confgured to not wrap and to display 
     *  only one line of text.  That's the most efficient rendering mode.  This 
     *  property is false by default, which means that multiline and wordWrap are 
     *  enabled (true) and autoSize is LEFT.
     */    
    public function get singleLine():Boolean
    {
        return _singleLine
    }
    
    /**
     *  @private
     */    
    public function set singleLine(value:Boolean):void
    {
        if (_singleLine == value)
            return;
        
        _singleLine = value;
        
        labelDisplay.multiline = !singleLine;  // can be reset, see updateMeasuredSize()
        labelDisplay.wordWrap = !singleLine;
    }    
    
    //----------------------------------
    //  dragging
    //----------------------------------
    
    private var _dragging:Boolean = false;
    
    [Bindable("draggingChanged")]        
    
    /**
     *  @inheritDoc
     * 
     *  @default false
     */
    public function get dragging():Boolean
    {
        return _dragging;
    }
    
    /**
     *  @private  
     */
    public function set dragging(value:Boolean):void
    {
        if (_dragging == value)
            return;
        
        _dragging = value;
        dispatchChangeEvent("draggingChanged");        
    }
    
    //----------------------------------
    //  label
    //----------------------------------
    
    private var _label:String = "";
    
    [Bindable("labelChanged")]
    
    /**
     *  @inheritDoc
     *  
     *  <p>The Grid sets this property to the value of the column's <code>itemToLabel()</code> method, before
     *  calling <code>preprare()</code>.</p>   
     *
     *  @default ""  
     */
    public function get label():String
    {
        return _label;
    }
    
    /**
     *  @private
     */ 
    public function set label(value:String):void
    {
        if (_label == value)
            return;
        
        _label = value;
        invalidateDisplayList();
        // Defer setting the labelDisplay's text property to avoid extra computation, see updateMeasuredSize()
        
        dispatchChangeEvent("labelChanged");
    }
    
    //----------------------------------
    //  labelDisplay
    //----------------------------------
    
    private var _labelDisplay:IUITextField = null;
    
    [Bindable("labelDisplayChanged")]
    
    /**
     *  An optional component for displaying the label property.   If specified, this component's
     *  <code>text</code> will be kept in sync with this renderer's <code>label</code>.
     * 
     *  @default null
     */    
    public function get labelDisplay():IUITextField
    {
        return _labelDisplay
    }
    
    /**
     *  @private
     */    
    public function set labelDisplay(value:IUITextField):void
    {
        if (_labelDisplay == value)
            return;
        
        _labelDisplay = value;
        invalidateSize();
        dispatchChangeEvent("labelDisplayChanged");        
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------    
    
    /**
     *  @inheritDoc
     */
    public function prepare(willBeRecycled:Boolean):void
    {
    }
    
    /**
     *  @inheritDoc
     */
    public function discard(hasBeenRecycled:Boolean):void
    {
    }

    //--------------------------------------------------------------------------
    //
    //  Overridden methods: UIComponent
    //
    //--------------------------------------------------------------------------
    
    private function createLabelDisplay():void
    {
        if (labelDisplay)
            removeChild(DisplayObject(labelDisplay));
        
        labelDisplay = IUITextField(createInFontContext(UITextField));
        labelDisplay.multiline = true;  // consistent with singleLine=false (the default)
        labelDisplay.wordWrap = true;
        labelDisplay.autoSize = TextFieldAutoSize.NONE;
        
        // The default width of a TextField is 100.  If autoWrap is true, and
        // multiline is true, the measured text will wrap if it is wider than
        // the TextField's width. This is not what we want when measuring the 
        // width of typicalItem columns that lack an explicit GridColumn width.
        
        labelDisplay.setActualSize(4096, NaN);  // 4096 is just an arbitrarily large value
        
        addChild(DisplayObject(labelDisplay));
    }
    
    /**
     *  @private
     */
    override protected function commitProperties():void
    {
        super.commitProperties();
        
        if (!labelDisplay || hasFontContextChanged())
            createLabelDisplay();
        
        if (lineBreakStyleChanged)
        {
            singleLine = getStyle("lineBreak") == "explicit";
            lineBreakStyleChanged = false;
        }
    }
    
    /**
     *  @private
     */
    override public function styleChanged(styleName:String):void
    {
        super.styleChanged(styleName);
        
        if (!styleName || (styleName == "styleName") || (styleName = "lineBreak"))
        {
            lineBreakStyleChanged = true;
            invalidateProperties();
        }
    }
    
    
    /**
     *  @private
     *  The renderer's measuredWidth,Height are just padded versions of the labelDisplay's
     *  textWidth,Height properties.   The code below is based on the UITextField
     *  meausuredWidth,Height get methods, although we do not call validateNow() here (as
     *  they do).
     *  
     */
    private function updateMeasuredSize():void
    {
        if (getStyle("lineBreak") == "explicit")
            labelDisplay.multiline = _label.indexOf("\n") != -1;
         
        labelDisplay.text = _label;  // forces a labelDisplay.validateNow(), if text has changed

        const widthPadding:int = WIDTH_PADDING + UITextField.TEXT_WIDTH_PADDING;
        const heightPadding:int = HEIGHT_PADDING + UITextField.TEXT_HEIGHT_PADDING
        
        if (!labelDisplay.stage || labelDisplay.embedFonts)
        {
            measuredWidth = labelDisplay.textWidth + widthPadding;
            measuredHeight = labelDisplay.textHeight + heightPadding;
        }
        else 
        {
            const m:Matrix = labelDisplay.transform.concatenatedMatrix;      
            measuredWidth = Math.abs((labelDisplay.textWidth * m.a / m.d)) + widthPadding;
            measuredHeight  = Math.abs((labelDisplay.textHeight * m.a / m.d)) + heightPadding;
        }
    }
    
    /**
     *  @private
     */
    override protected function measure():void
    {
        super.measure();  // initializes measured{Min}Width,Height to 0
        updateMeasuredSize();
    }
    
    /**
     *  @private
     *  True if the labelDisplay's scrollRect has been set.  See below.
     */
    private var clippingEnabled:Boolean = false;
    
    /**
     *  @private
     *  Watch Out: this code relies on the fact that UITextField/setActualSize() can cause
     *  labelDisplay.textHeight to change, if the text wraps.  The textfield's measuredHeight
     *  is just a padded version of textHeight.  This is the only place where labelDisplay.setActualSize() 
     *  is called, so we update the measuredHeight of this render here.  Very unconventional.
     *  Doing so is essential because after this code runs, i.e. after GridLayout/layoutItemRenderer()
     *  invokes validateNow() on this renderer, it uses the renderer's preferredBoundsHeight()
     *  (that's the measuredHeight in our case) to update the overall row height.
     */
    override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
    {
        super.updateDisplayList(width, height);

        if ((unscaledWidth == 0) || (unscaledHeight == 0))
            return;
        
        // We shrink the available space by one pixel to avoid rendering on top of the 
        // default row and column separators.
        
        const labelDisplayX:int = 5;
        const labelDisplayY:int = 4;
        const labelDisplayWidth:int = Math.floor(unscaledWidth - 1) - (WIDTH_PADDING - labelDisplayX); 
        const labelDisplayHeight:int = Math.floor(unscaledHeight - 1) - (HEIGHT_PADDING - labelDisplayY);
        
        labelDisplay.setActualSize(labelDisplayWidth, labelDisplayHeight);  // setActualSize() side-effects labelDisplay.textHeight
        updateMeasuredSize();  // See @private comment above
        
        labelDisplay.move(labelDisplayX, labelDisplayY);
    }
 
        
}   
}