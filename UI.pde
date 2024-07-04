import java.util.function.Consumer;

// features to implement:
// - position relative to window size (precentage)

// inputbox:
// - default text
// - max text length
// - two types of callback functions
//      - activate on pressing enter
//      - activate when text is changed (async version)

// button:
// - text
// - edge roundness


// anchor positions:
//                left , center, right
public final int TL = 0, TC = 1, TR = 2; // top
public final int ML = 3, MC = 4, MR = 5; // middle
public final int BL = 6, BC = 7, BR = 8; // bottom


// general properties:
// - position: fixed to coordinates, fixed to ratio
// - anchor point: TL (top-left), TC, TR, ML, MC (middle-center), MR, BL, BC, BR (bottom-right)
// - size: width, height
// - callback function (Consumer)
// - (colors are adjustable by the default processing funcitons like stroke())
// - methods: display, update, display and update at the same time

public abstract class UIElement
{
    // properties
    protected PVector position = new PVector(0, 0);
    protected final PVector corner = new PVector();
    protected final PVector anchor = new PVector(.5f, .5f); // relative axis-normalized anchor point inside the ui element

    protected float width, height;
    public float roundness = 0;

    protected Consumer callback;


    // getters, setters
    public UIElement setPosition(PVector position)
    {
        this.position = position.copy();
        updateCorner();

        return this;
    }

    public UIElement setAnchor(int a)
    {
        switch (a)
        {
            case TL:
                anchor.set(.0f, .0f);
                break;
            case TC:
                anchor.set(.5f, .0f);
                break;
            case TR:
                anchor.set(1.f, .0f);
                break;
            case ML:
                anchor.set(.0f, .5f);
                break;
            case MC:
                anchor.set(.5f, .5f);
                break;
            case MR:
                anchor.set(1.f, .5f);
                break;
            case BL:
                anchor.set(.0f, 1.f);
                break;
            case BC:
                anchor.set(.5f, 1.f);
                break;
            case BR:
                anchor.set(1.f, 1.f);
                break;
            default:
                anchor.set(.5f, .5f);
                break;
        }

        updateCorner();
        return this;
    }

    public float getWidth()
    {
        return this.width;
    }
    public float getHeight()
    {
        return this.height;
    }
    public void setWidth(float width)
    {
        this.width = width;
        updateCorner();
    }
    public void setHeight(float height)
    {
        this.height = height;
        updateCorner();
    }

    protected void updateCorner()
    {
        corner.set(position.x - this.width * anchor.x, position.y - this.height * anchor.y);
    }


    // constructor(s)
    public UIElement(PVector position, float width, float height, Consumer callback)
    {
        this.setPosition(position);
        this.width = width;
        this.height = height;
        this.callback = callback;
    }

    public UIElement(PVector position, float width, float height, float roundness, Consumer callback)
    {
        this(position, width, height, callback);
        this.roundness = min(width, min(height, roundness));
    }

    // methods
    public void refresh() // display and update
    {
        update();
        display();
    }

    public abstract void display();
    public abstract void update();
}


// UI group: refresh ui elements at the same time

public class ElementGroup extends ArrayList<UIElement>
{
    public ElementGroup()
    {
        
    }

    public ElementGroup(ElementGroup elementGroup)
    {
        super(elementGroup);
    }

    // methods that work: add, remove and all the methods of ArrayList

    public void display()
    {
        for (UIElement element : this)
        {
            element.display();
        }
    }

    public void update()
    {
        for (UIElement element : this)
        {
            element.update();
        }
    }

    public void refresh()
    {
        display();
        update();
    }
}


// checkbox:
// - checked
// - edge roundness

public class CheckBox extends UIElement
{
    // properties
    private boolean checked = false;

    private boolean prevPressed = false;
    private boolean pressed = false;


    // getters, setters
    public boolean isChecked()
    {
        return checked;
    }


    // constructors
    public CheckBox(PVector position, float size, Consumer callback)
    {
        super(position, size, size, callback);
    }

    public CheckBox(PVector position, float size, boolean checked, Consumer callback)
    {
        super(position, size, size, callback);
        this.checked = checked;
    }

    public CheckBox(PVector position, float size, float roundness, boolean checked, Consumer callback)
    {
        super(position, size, size, roundness, callback);
        this.checked = checked;
    }


    // main methods 
    public void display()
    {
        rect(corner.x, corner.y, this.width, this.height, this.roundness);

        if (checked)
        {
            float hw = this.width * .5f, hh = this.height * .5f;
            float cx = corner.x + hw, cy = corner.y + hh;

            color strokeColor = getStroke();
            color fillColor = getFill();
            float weight = getStrokeWeight();
            float l = (red(fillColor) + green(fillColor) + blue(fillColor)) / 3f > 128f ? 0f : 1f;

            stroke(l);
            strokeWeight(width * .1f);
            line(cx - hw * .6f, cy - hh * .6f, cx + hw * .6f, cy + hh * .6f);
            line(cx - hw * .6f, cy + hh * .6f, cx + hw * .6f, cy - hh * .6f);
            stroke(strokeColor);
            strokeWeight(weight);
        }
    }

    public void update()
    {
        if (mousePressed && pointInRect(corner.x, corner.y, this.width, this.height, new PVector(mouseX, mouseY))) pressed = true;
        else pressed = false;

        if (pressed && !prevPressed)
        {
            checked = !checked;
            if (callback != null) callback.accept(this);
        }

        prevPressed = pressed;
    }
}


// slider:
// - value
// - default value
// - sliding element width
// - (async callback option)

public abstract class Slider extends UIElement
{
    // properties
    protected float value = 0; // normalized (range: 0.0 - 1.0)
    protected float prevValue = 0;
    protected float thumbSize = .05f; // relative to width or height

    protected PVector clicked = null;
    protected boolean prevPressed = false;
    protected boolean asyncCallback = false;

    protected color thumbColor = color(128f);


    // getters, setters
    public float getValue()
    {
        return value;
    }

    public Slider setThumbColor(color thumbColor)
    {
        this.thumbColor = thumbColor;
        return this;
    }

    public Slider setASyncCallback(boolean asyncCallback)
    {
        this.asyncCallback = asyncCallback;
        return this;
    }


    // constructor(s)
    public Slider(PVector position, float width, float height, Consumer callback)
    {
        super(position, width, height, callback);
    }

    public Slider(PVector position, float width, float height, float roundness, Consumer callback)
    {
        super(position, width, height, roundness, callback);
    }

    public Slider(PVector position, float width, float height, float roundness, float value, Consumer callback)
    {
        super(position, width, height, roundness, callback);
        this.value = clamp(value, 0f, 1f);
        this.prevValue = this.value;
    }

    public Slider(PVector position, float width, float height, float roundness, float value, float thumbSize, Consumer callback)
    {
        this(position, width, height, roundness, value, callback);
        this.thumbSize = clamp(thumbSize, 0f, 1f);
    }
}

public class HorizontalSlider extends Slider
{
    // constructor(s)
    public HorizontalSlider(PVector position, float width, float height, Consumer callback)
    {
        super(position, width, height, callback);
    }

    public HorizontalSlider(PVector position, float width, float height, float roundness, Consumer callback)
    {
        super(position, width, height, roundness, callback);
    }

    public HorizontalSlider(PVector position, float width, float height, float roundness, float value, Consumer callback)
    {
        super(position, width, height, roundness, value, callback);
    }

    public HorizontalSlider(PVector position, float width, float height, float roundness, float value, float thumbSize, Consumer callback)
    {
        super(position, width, height, roundness, value, thumbSize, callback);
    }

    // main methods     
    public void display()
    {
        // track
        rect(corner.x, corner.y, this.width, this.height, this.roundness);


        // thumb
        float weight = getStrokeWeight();
        color fillColor = getFill();

        float thumbX = corner.x + roundness * .5f + value * (this.width * (1f - thumbSize) - roundness);
        float thumbY = corner.y;

        fill(thumbColor);
        strokeWeight(1.5f);
        rect(thumbX, thumbY, this.width * thumbSize, this.height, this.roundness);
        fill(fillColor);
        strokeWeight(weight);
    }

    public void update()
    {
        PVector mousePos = new PVector(mouseX, mouseY);

        float thumbX = corner.x + roundness * .5f + value * (this.width * (1f - thumbSize) - roundness);
        float thumbY = corner.y;
        boolean mouseOnThumb = pointInRect(thumbX, thumbY, this.width * thumbSize, this.height, mousePos);

        if (mousePressed && mouseOnThumb) clicked = new PVector(mouseX - thumbX, mouseY - thumbY);
        else if (!mousePressed && prevPressed) clicked = null;

        if (clicked != null)
        {
            value = map(mouseX - clicked.x, corner.x + roundness * .5f, corner.x + this.width * (1f - thumbSize) - roundness * .5f, 0f, 1f);
            value = clamp(value, 0f, 1f);

            if (callback != null && prevValue != value)
            {
                if (!asyncCallback) callback.accept(this);
                else
                {
                    final HorizontalSlider hs = this;
                    (new Thread()
                    {
                        public void run()
                        {
                            callback.accept(hs);
                        }
                    }).run();
                }
            }

            prevValue = value;
        }

        prevPressed = mousePressed;
    }
}

public class VerticalSlider extends Slider
{
    // constructor(s)
    public VerticalSlider(PVector position, float width, float height, Consumer callback)
    {
        super(position, width, height, callback);
    }

    public VerticalSlider(PVector position, float width, float height, float roundness, Consumer callback)
    {
        super(position, width, height, roundness, callback);
    }

    public VerticalSlider(PVector position, float width, float height, float roundness, float value, Consumer callback)
    {
        super(position, width, height, roundness, value, callback);
    }

    public VerticalSlider(PVector position, float width, float height, float roundness, float value, float thumbSize, Consumer callback)
    {
        super(position, width, height, roundness, value, thumbSize, callback);
    }

    // main methods
    public void display()
    {
        // track
        rect(corner.x, corner.y, this.width, this.height, this.roundness);


        // thumb
        float weight = getStrokeWeight();
        color fillColor = getFill();

        float thumbX = corner.x;
        float thumbY = corner.y + roundness * .5f + value * (this.height * (1f - thumbSize) - roundness);

        fill(thumbColor);
        strokeWeight(1.5f);
        rect(thumbX, thumbY, this.width, this.height * thumbSize, this.roundness);
        fill(fillColor);
        strokeWeight(weight);
    }

    public void update()
    {
        PVector mousePos = new PVector(mouseX, mouseY);

        float thumbX = corner.x;
        float thumbY = corner.y + roundness * .5f + value * (this.height * (1f - thumbSize) - roundness);
        boolean mouseOnThumb = pointInRect(thumbX, thumbY, this.width, this.height * thumbSize, mousePos);

        if (mousePressed && mouseOnThumb) clicked = new PVector(mouseX - thumbX, mouseY - thumbY);
        else if (!mousePressed && prevPressed) clicked = null;

        if (clicked != null)
        {
            value = map(mouseY - clicked.y, corner.y + roundness * .5f, corner.y + this.height * (1f - thumbSize) - roundness * .5f, 0f, 1f);
            value = clamp(value, 0f, 1f);

            if (callback != null && prevValue != value)
            {
                if (!asyncCallback) callback.accept(this);
                else
                {
                    final VerticalSlider hs = this;
                    (new Thread()
                    {
                        public void run()
                        {
                            callback.accept(hs);
                        }
                    }).run();
                }
            }

            prevValue = value;
        }

        prevPressed = mousePressed;
    }
}

// UTILITIES

private color getStroke()
{
    int sc = g.strokeColor;

    int alpha = (sc >> 24) & 0xFF;
    int red   = (sc >> 16) & 0xFF;
    int green = (sc >>  8) & 0xFF;
    int blue  = (sc >>  0) & 0xFF;

    return color(red, green, blue, alpha);
}

private float getStrokeWeight()
{
    return g.strokeWeight;
}

private color getFill()
{
    int fc = g.fillColor;
    
    int alpha = (fc >> 24) & 0xFF;
    int red   = (fc >> 16) & 0xFF;
    int green = (fc >>  8) & 0xFF;
    int blue  = (fc >>  0) & 0xFF;

    return color(red, green, blue, alpha);
}

private boolean pointInRect(float x, float y, float width, float height, PVector point)
{
    return point.x >= x && point.x <= x + width && point.y >= y && point.y <= y + height; 
}

private float clamp(float val, float min, float max)
{
    return min(max(val, min), max);
}